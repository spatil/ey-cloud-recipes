#!/usr/bin/ruby

# Filename: binary_log_purge.rb
# Author: Tyler Poland
# Version: 0.2
# Purpose: Script to check current state of all replica databases and
# 	purge binary logs from the master based on the position of any
# 	and all replica databases.

# Changelog 0.1 -> 0.2
# - modified binlog check routine to lookup binary log storage in configuration file instead of relying on
#   binary logs being stored in the data directory

# Changelog 0.2 -> 0.3
# - Added ability to purge binary logs for standalone master databases

# Changelog 0.3 -> 0.4
# - Added support for remote tunneled slave with reverse connection on port 13306

# Changelog 0.4 -> 1.0 
# - Add automatic create user for master to connect to replica

require 'net/smtp'
require 'mysql'
require 'yaml'
require 'open3'
require 'getoptlong'

# Set up logging functions based on desired verbosity level
def log_info(message)   # may get redefined below
  puts message
end

def log_error(message)
  STDERR.write(message + "\n")
end

opts = GetoptLong.new(['--quiet', '-q', GetoptLong::NO_ARGUMENT])
opts.each do |opt, arg|
  if opt == '--quiet'
    def log_info(_) end
  end
end


log_info Time.now
# Conditional require for JSON if dna file exists
chef_file = '/etc/chef/dna.json'
if File.exists?(chef_file)
  require 'rubygems'
  require 'json'
end

# Modify default purge count
keep_logs = 5
binpurge_config = '/etc/.binlogpurge.yml'
if File.exists?(binpurge_config)
  options = YAML::load(File.read(binpurge_config))
  if options['keep'] > 0
    keep_logs = options['keep'] 
    log_info "Overriding keep logs from configuration file"
  end
end

# function to send error emails
def failure_message(message)
  sender = "Database Team <db@engineyard.com"
  recipients = "db@engineyard.com"
  hostname = `hostname`.chomp
  subject = "An error has occurred while purging binary logs on #{hostname}"
    mailtext = <<EOF
From: #{sender}
To: #{recipients}
Subject: #{subject}
#{message}
EOF
	
  begin Net::SMTP.start('mail') do |smtp|
    smtp.sendmail(mailtext, 'root@' + hostname, recipients)
  end
  rescue Exception => e
    log_error "Exception occurred: " + e
  end
  
  exit(1)
end

# function to retrieve password from .mytop file
def get_password
  dbpass = %x{cat /root/.mytop |grep pass |awk -F= '{print $2}'}.chomp
  failure_message() if dbpass.length < 1
  dbpass
end

# function to run query against database
def run_query(host, user, password, query)
  options = ''
  if host == '127.0.0.1'
    options = options + ' -P13306'
  end
  stdin, stdout, stderr = Open3.popen3("mysql -u#{user} -p#{password} #{options} -h#{host} -N -e\"#{query}\"")
  query_error = stderr.read
  if query_error.length > 0
    log_error "Error caught: #{query_error}"
    test_add_privilege(user, password, query_error)
    exit 0
  end
  rs = stdout.read
end

# function to test for user privilege
def test_add_privilege(user, password, error)
  full_hostname = %x{hostname --long}.chomp
  dns_name = %x{hostname -d}.chomp
  # verify that this is the user privilege error with the root user not having access to the replica
  if error.match(/ERROR 1045.* Access denied for user 'root'@'.*#{dns_name}' \(using password: YES\)/)
    # check the master to see if grant based on hostname or IP exists
    master_ip = %x{hostname -i}.chomp.gsub(/\s+/,'')
    stdin, stdout, stderr = Open3.popen3("mysql -u#{user} -p#{password} -e\"show grants for 'root'@'#{master_ip}'\"")
    master_ip_error = stderr.read

    stdin, stdout, stderr = Open3.popen3("mysql -u#{user} -p#{password} -e\"show grants for 'root'@'#{full_hostname}'\"")
    full_hostname_error = stderr.read
    
    regex = 'ERROR 1141.*There is no such grant defined'
    if master_ip_error.match(/#{regex}/) || full_hostname_error.match(/#{regex}/)
      # neither grant is defined on the master so go ahead and add it
      log_info "The user privilege does not exist on the master, the script will now create it."
      log_info "This privilege must propagate to the replica via replication, the user may not be available for immediate use."
      stdin, stdout, stderr = Open3.popen3("mysql -u#{user} -p#{password} -e\"grant all privileges on *.* to 'root'@'#{master_ip}' identified by '#{password}'\"")
      create_user_error = stderr.read
      if create_user_error.length > 0
        log_error "Unable to create user: #{create_user_error}"
        exit 1
      end
    else
      log_error "The required privilege appears to exist on the master, you may need to wait for replication to process the grant on the Replica"
      exit 0
    end
  end
end

# function to convert input into yaml
def yaml_result(file)
  parse = file.gsub(/^\*.*$/,'').gsub(/^/,' ').gsub(/^\s+/, '  ')
  yml = YAML.load(parse)
end

# parse the hostname out of the processlist
def extract_host(line)
  line =~ /.+\s+(.+):.+/
  $1
end

# function to get replica position from replica host
def slave_log_file(hostname, user, pass)
  if hostname == 'localhost'
    hostname = '127.0.0.1'
  end
  
  q_result = run_query(hostname, user, pass, "show slave status\\G")
  if q_result.match(/.*Slave_SQL_Running: No.*/)
    log_error "Slave SQL thread is not running."
    log_info "The error is: \n#{q_result}"
    log_error "Unable to continue; exiting!"
    exit 1
  end
   
  yaml = yaml_result(q_result)
  yaml["Relay_Master_Log_File"]
end

dbuser = 'root'

if not dbpassword = get_password
  failure_message("Password not found for slice, check for /root/.mytop")
end

mysql_process = %x{ps -ef|grep '[m]ysqld'}.split(/\s+/).select{|item| item.match(/^--/)}
mysql_params = Hash.new
mysql_process.each {|i| k, v = i.split('='); mysql_params[k]=v}
datadir = mysql_params['--datadir']
config_file = mysql_params['--defaults-file']
binlog_dir = File.dirname(%x{cat #{config_file} |egrep '^log-bin'|grep -v '.index'|awk -F= '{print $2}'}.gsub(/\s+/,'').chomp)


# If master-bin.000001 exists then only purge logs if disk space is constrained
binary_log_name = %x{cat #{config_file}|grep '^log-bin'|grep -v 'index' |awk -F= '{print $2}'}.gsub(/\s/,'')
if binary_log_name == ''
	log_info "log-bin not set in config file, host does not have master role, unable to proceed"
	exit(0) 
end
if File.exists?(binary_log_name + '.000001')
  purge_threshold = 90 
  if %x{df -h |egrep "/db" |awk '{print $5}'}.to_i < purge_threshold
    log_info "The first binary log exists and the purge threshold has not been reached; skipping purge action"
    exit(0)
  end
end

# Check master for all connected replication slaves
result = run_query('localhost', dbuser, dbpassword, 'show processlist')
slave_hosts = []
min_log = 0 
result.each do |line|
  if line.include? 'Binlog Dump'
    slave = Hash.new
    slave["hostname"] = extract_host(line)
    slave["Relay_Master_Log_File"] = slave_log_file(slave["hostname"], dbuser, dbpassword)
    slave["Relay_Master_Log_File"] =~ /\w+.(\d{6})/ and min_log = $1.to_i if $1.to_i < min_log || min_log == 0
    log_info "Slave Hostname: #{slave["hostname"]}, Relay_Master_log: #{slave["Relay_Master_Log_File"]}"
    slave_hosts << slave
  end
end

# stop log purge #{keep_logs} logs before the current read position
stop_log = min_log - keep_logs

# if standalone master and no replicas are found we stop purge #{keep_logs} logs before master's current position
if min_log == 0 and File.exists?(chef_file)
  chef_config = JSON.parse(File.read(chef_file))
  if chef_config['db_slaves'].empty? or chef_config['db_slaves'].nil?
    current_master = %x{cd #{binlog_dir} && ls -tr master-bin.[0-9]* | tail  -n 1}
    current_master =~ /\w+.(\d{6})/ and stop_log = $1.to_i + 1 - keep_logs
  elsif min_log == 0
    log_error "Slave is on record as '#{chef_config['db_slaves']}' but replication is not running."
    exit 1
  end
end


# Purge logs based on minimum position of all servers
min_master_log = %x{cd #{binlog_dir} && ls -tr master-bin.[0-9]* | head -n 1}
min_master_log =~ /\w+.(\d{6})/ and min_master_num = $1.to_i + 1

min_master_num.upto(min_master_num + 10) do |i|
# purge up to 10 files as long as the top file is less than the minimum replica log
  if stop_log < 0
    log_error "Could not verify replication status, confirm that replication is running.  Exiting!"
    break
  elsif i >= stop_log + 1
    log_info "File number of #{i} exceeds minimum purge file of #{stop_log + 1} based on keeping #{keep_logs} files.  Exiting!"
    break
  end
  file = "master-bin.%06d" % i
  log_info "Purging binary logs to #{file}"
  run_query('localhost', dbuser, dbpassword, "purge master logs to '#{file}'")
  sleep 120
end

log_info Time.now

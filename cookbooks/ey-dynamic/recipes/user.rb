#
# Cookbook Name:: ey-dynamic
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "users" do
  message "processing users"
end

## EY role account should come first in the node[:users] array
node[:users].each do |user_obj|
  execute "create-group" do
    command "groupadd -g #{user_obj[:gid]} #{user_obj[:username]}"
    not_if "getent group #{user_obj[:gid]}"
  end

  script "set password #{user_obj[:username]}" do
    code %Q{
      require 'rubygems'
      require 'open4'
      require 'expect'
      Open4::popen4("passwd %s 2>&1" % "#{user_obj[:username]}" ) do |pid, sin, sout, serr|
        $expect_verbose = true
        2.times do
          sout.expect(/:/)
          sleep 0.1 
          sin.puts "#{user_obj[:password]}" + "\n"
        end
      end
  }
    interpreter "ruby"
    action :nothing
  end
  
  user "create-user" do
    username user_obj[:username]
    uid user_obj[:uid]
    gid user_obj[:gid].to_i if user_obj[:gid]
    shell "/bin/bash"
    password user_obj[:password]
    comment user_obj[:comment]
    supports :manage_home => false
    notifies :run, resources(:script => "set password #{user_obj[:username]}")
    not_if "getent passwd #{user_obj[:uid]}"
  end
  
  execute "update-username" do
    command "usermod -l #{user_obj[:username]} --home /home/#{user_obj[:username]} --move-home `getent passwd #{user_obj[:uid]} | cut -d \":\" -f 1` && groupmod --new-name #{user_obj[:username]} `getent group #{user_obj[:uid]} | cut -d \":\" -f 1`"
    only_if do user_obj[:username] != `getent passwd #{user_obj[:uid]} | cut -d \":\" -f 1`  end
  end
  
  directory "/data/homedirs/#{user_obj[:username]}" do
    owner user_obj[:uid]
    group user_obj[:gid]
    mode 0755
    recursive true
  end
  
  link "/home/#{user_obj[:username]}" do
    to "/data/homedirs/#{user_obj[:username]}"
  end
  
  execute "add base dotfiles" do
    command "rsync -aq /etc/skel/ /home/#{user_obj[:username]}"
    not_if { File.exists? "/home/#{user_obj[:username]}/.bashrc" }
  end
  
  execute "chown homedir to user" do
    command "chown -R #{user_obj[:username]}:#{user_obj[:username]} /data/homedirs/#{user_obj[:username]}"
  end
  
  execute "add framework env to /etc/profile" do
    # Remove any MERB_ENV RACK_ENV RAILS_ENV from the config before we start so we update them
    command %Q{
      sed -e '/RACK_ENV/d' -e '/MERB_ENV/d' -e '/RAILS_ENV/d' -i /etc/profile
      echo "export RAILS_ENV='#{node[:environment][:framework_env]}'" >> /etc/profile
      echo "export MERB_ENV='#{node[:environment][:framework_env]}'" >> /etc/profile
      echo "export RACK_ENV='#{node[:environment][:framework_env]}'" >> /etc/profile
    }
  end
    
end

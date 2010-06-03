#
# Cookbook Name:: ntp
# Recipe:: default
#
# Useful References:
# http://en.gentoo-wiki.com/wiki/NTP#Configuration
#
# Caveats:
# If your instance has 5 minutes or more of clock
# skew, the custom recipes will simply fail to run.


# Install the required package.
package "net-misc/ntp" do
  version '4.2.4_p4-r1'
  action :install
end

# Avoid the "cap_set_proc() failed to drop root
# privileges: Operation not permitted" error when
# switching to the ntp:ntp user.
execute "ensure-user-switching-works" do
  command "modprobe capability"
end

# All instances get their time from the host machine's
# hardware clock by default and ntpd won't be able to
# make adjustments while it's being managed like that.
# This will allow the instance to self-manage its clock.
execute "disassociate-time-from-hardware-clock" do
  command "echo 1 > /proc/sys/xen/independent_wallclock"
end

# We're using the default for now, but copy over
# the existing one in case we ever want to change
# anything.
template "/etc/ntp.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "ntp.conf.erb"
  variables :servers    => ["pool.ntp.org"],
            :driftfile  => "/var/lib/ntp/ntp.drift",
            :restricts  => ["default nomodify nopeer",
                            "127.0.0.1"]
end

# Make sure ntpd is starts at boot and stays running.
runlevel 'ntpd' do
  action :add
end

# By default, ntpd is started with the -g option, which allows it to
# make large clock adjustments. We don't want to do this, as it may
# cause trouble in running applications if the clock jumps around.
remote_file "/etc/conf.d/ntpd" do
  owner 'root'
  group 'root'
  mode 0644
  source "ntpd"
end

# Make sure ntpd is running
execute "ensure-ntpd-is-running" do
  action :nothing

  command "/etc/init.d/ntpd restart"

  subscribes :run, resources(:remote_file => "/etc/conf.d/ntpd"), :immediately
end

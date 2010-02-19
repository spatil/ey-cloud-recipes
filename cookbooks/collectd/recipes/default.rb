#
# Cookbook Name:: collectd
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "collectd" do
  message 'processing performance monitoring'
end

template "/etc/mini_httpd.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "mini_httpd.conf.erb"
  variables({
    :log => '/var/log/engineyard/mini_httpd.log',
    :pid => '/var/run/mini_httpd.pid',
    :host => '0.0.0.0',
    :port => '8989'
  })
end

template "/etc/conf.d/mini_httpd" do
  owner 'root'
  group 'root'
  mode 0644
  source "mini_httpd.erb"
  variables({
    :docroot => "/var/www/localhost/htdocs"
  })
end

directory "/var/www/localhost/htdocs" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

execute "start-mini-httpd" do
  command %Q{
    echo "/etc/init.d/mini_httpd restart" | at now
  }
  not_if "/etc/init.d/mini_httpd status"
end

memcached = any_app_needs_recipe?('memcached')

template "/engineyard/bin/ey-alert.rb" do
  owner 'root'
  group 'root'
  mode 0755
  source "ey-alert.erb"
  variables({
    :url => node[:reporting_url]
  })
end

managed_template "/opt/collectd/etc/collectd.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "collectd.conf.erb"
  variables({
    :databases => node[:applications].map {|app, _| app},
    :memcached => memcached,
    :user => node[:owner_name],
    :alert_script => "/engineyard/bin/ey-alert.rb",
    :load_warning => node[:collectd][:load][:warning],
    :load_failure => node[:collectd][:load][:failure]
  })
end

execute "install-graphs-app" do
  command %Q{
    curl https://ey-ec2.s3.amazonaws.com/graphs.tgz -O &&
    tar xvzf graphs.tgz &&
    cp -R graphs/lib/Collectd /usr/lib/perl5/vendor_perl/5.8.8/ &&
    cp -R graphs/lib/Config /usr/lib/perl5/vendor_perl/5.8.8/ &&
    cp -R graphs/lib/HTML /usr/lib/perl5/vendor_perl/5.8.8/ &&    
    cp -R graphs /var/www/localhost/htdocs/ &&
    chmod +x /var/www/localhost/htdocs/graphs/bin/* &&
    rm -rf graphs*
  }
  not_if { File.directory?('/var/www/localhost/htdocs/graphs') }
end

execute "install-http-auth" do
  command %Q{
    htpasswd -cb /var/www/localhost/htdocs/graphs/.htpasswd  engineyard 1000slices &&
    htpasswd -cb /var/www/localhost/htdocs/graphs/bin/.htpasswd  engineyard 1000slices
  }
  not_if {File.exists?('/var/www/localhost/htdocs/graphs/.htpasswd')}
end

execute "add-mini-httpd-to-init" do
  command %Q{
    rc-update add mini_httpd default
  }
  not_if "rc-status | grep mini_httpd"
end

bash "add-collectd-to-init" do
  cmd = "cd:345:respawn:/opt/collectd/sbin/collectd -f"
  code <<-EOH
echo "# for collectd" >> /etc/inittab && echo "#{cmd}" >> /etc/inittab
telinit q
EOH
  not_if "grep '#{cmd}' /etc/inittab"
end

execute "ensure-collectd-has-fresh-config" do
  command %Q{
    pkill -9 collectd;true
  }
end

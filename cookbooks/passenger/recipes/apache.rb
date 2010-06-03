directory "/data/apache2" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
end

execute "copy /etc/apache2 to /data" do
  command "cp -R /etc/apache2/* /data/apache2/"
  not_if { File.symlink?('/etc/apache2') }
end


execute "ensure apache is on /data and no old vhosts exist" do
  command %Q{
    rm -rf /etc/apache2 &&
    ln -nfs /data/apache2 /etc/apache2
  }
end

execute "ensure-no-default-vhosts" do
  command %Q{
    rm /data/apache2/vhosts.d/*default*
  }
  not_if { Dir.glob("/data/apache2/vhosts.d/*default*").empty? }
end

link "/etc/apache2" do
  to "/data/apache2"
end

execute "install-passenger-module" do
  command %Q{
    yes | passenger-install-apache2-module
  }
  not_if { Dir.glob("/usr/lib/ruby/gems/1.8/gems/passenger-#{node[:passenger_version]}/ext/apache2/mod_passenger.so").size > 0 }
end  

pool_size = get_pool_size()

managed_template "/data/apache2/httpd.conf" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0655
  source "httpd.conf.erb"
  variables({
      :poolsize => pool_size,
      :version => node[:passenger_version],
    }.merge(node[:members] ? {:http_bind_port => 81} : {:http_bind_port => 80}))
  action :create
end

execute "turn-off-default-vhost" do
  command %Q{
    perl -i -pe 's!APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D LANGUAGE -D SSL -D SSL_DEFAULT_VHOST"!APACHE2_OPTS=" -D INFO -D LANGUAGE -D SSL"!' /etc/conf.d/apache2
  }
  only_if %Q{grep 'APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D LANGUAGE -D SSL"' /etc/conf.d/apache2}
end

execute "remove default vhosts" do
  command %Q{
    rm /data/apache2/vhosts.d/*default*
  }
  not_if { Dir.glob('/data/apache2/vhosts.d/*default*').empty? }
end

(node[:removed_applications]||[]).each do |app|
  execute "remove-old-apache-vhosts-for-#{app}" do
    command %Q{
      rm -rf /etc/apache2/vhosts.d/0*_#{app}_vhost.conf /etc/apache2/vhosts.d/0*_#{app}_ssl_vhost.conf
    }
  end
end

node[:applications].each_with_index do |(app, data), count|

  execute "remove-old-apache-vhosts-for-#{app}" do
    command %Q{
          rm -rf /etc/apache2/vhosts.d/0*_#{app}_vhost.conf;true
        }
  end

  managed_template "/etc/apache2/vhosts.d/0#{count}_#{app}_vhost.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0655
    source "app_vhost.conf.erb"
    variables({
        :app_type => data[:type],
        :docroot  => "/data/#{app}/current/public" ,
        :domain  => data[:vhosts].first[:name],
        :primary => (count == 0),
        :http_bind_port => node[:applications][app][:http_bind_port],
      }.merge(node[:members] ? {:http_bind_port => 81} : {}))
  end

  if data[:vhosts][1]

    execute "output-ssl-certs" do
      command %Q{
            echo '#{data[:vhosts][1][:key]}' > /data/apache2/ssl/#{app}.key
            echo '#{data[:vhosts][1][:crt]}' > /data/apache2/ssl/#{app}.crt
            echo '#{data[:vhosts][1][:chain]}' > /data/apache2/ssl/#{app}.chain
          }
    end

    execute "remove-old-apache-vhosts-for-#{app}" do
      command %Q{
            rm -rf /etc/apache2/vhosts.d/0*_#{app}_ssl_vhost.conf;true
          }
    end

    managed_template "/etc/apache2/vhosts.d/0#{count}_#{app}_ssl_vhost.conf" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0655
      source "app_ssl_vhost.conf.erb"
      variables({
          :app_type => data[:type],
          :docroot  => "/data/#{app}/current/public" ,
          :domain  => data[:vhosts][1][:name],
          :primary => (count == 0),
          :crt => "/data/apache2/ssl/#{app}.crt",
          :https_bind_port => 443,
          :key => "/data/apache2/ssl/#{app}.key",
          :chain => data[:vhosts][1][:chain].empty? ? nil : "/data/apache2/ssl/#{app}.chain"
        }.merge(node[:members] ? {:https_bind_port => 444} : {}))
    end

  else
    execute "ensure-no-old-ssl-vhosts-for-#{app}" do
      command %Q{
            rm -rf /etc/apache2/vhosts.d/0*_#{app}_ssl_vhost.conf;true
          }
    end
  end
end

execute "restart-apache" do
  command "/etc/init.d/apache2 restart"
  action :run
end

runlevel 'apache2' do
  action :add
end

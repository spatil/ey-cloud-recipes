package 'net-misc/memcached' do
  version '1.4.1'
  action :install
end

template "/etc/conf.d/memcached" do
  owner "root"
  group "root"
  mode 0644
  variables({
    :memcached_mem_limit => 128,
    :memcached_base_port => 11211
  })

  source "memcached.conf.erb"
  action :create_if_missing
end

monitrc "memcached", :memcached_base_port => 11211

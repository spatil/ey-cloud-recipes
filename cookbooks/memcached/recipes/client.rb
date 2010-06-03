node.engineyard.apps.each do |app|

  hostnames = node.engineyard.solo? ? ['127.0.0.1'] : node.engineyard.environment.enabled_app_servers_hostnames

  template "/data/#{app.name}/shared/config/memcached.yml" do
    owner node.engineyard.ssh_username
    group node.engineyard.ssh_username
    mode 0644
    variables(
      :backends             => hostnames,
      :memcached_mem_limit  => 128,
      :memcached_base_port  => 11211
    )
    source "memcached.yml.erb"
  end
end

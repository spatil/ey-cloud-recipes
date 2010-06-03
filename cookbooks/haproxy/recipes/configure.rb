execute 'deferred-reload-haproxy' do
  command "/etc/init.d/haproxy reload"
  action :nothing
end

managed_template "/etc/haproxy.cfg" do
  owner 'root'
  group 'root'
  mode 0644
  source "haproxy.cfg.erb"
  variables({
    :backends => node[:members],
    :haproxy_user => node[:haproxy][:username],
    :haproxy_pass => node[:haproxy][:password]
  })

  # Defer b/c haproxy may be configured but not installed yet
  notifies :run, resources(:execute => 'deferred-reload-haproxy')
end

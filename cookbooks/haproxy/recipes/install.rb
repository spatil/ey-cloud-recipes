package "net-proxy/haproxy" do
  version '1.4.2'
  action :install
end

runlevel 'haproxy' do
  action :add
end

execute "restart-haproxy" do
  command "/etc/init.d/haproxy restart"
  action :nothing

  subscribes :run, resources(:package => 'net-proxy/haproxy'), :immediately
end

# We might not have install a new version of HAproxy on a redeploy,
# so reload in case the config changed.
execute "reload-haproxy" do
  command "/etc/init.d/haproxy reload"
  action :run
end

define :link_after_deploy, :to => nil do
  resource = link(params[:name]) do
    to params[:to]

    action :nothing
  end

  node[:_after_deploy_resources] ||= {}
  node[:_after_deploy_resources][resource] = :create
end

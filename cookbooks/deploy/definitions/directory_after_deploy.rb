define :directory_after_deploy, :action => :create do
  resource = directory(params[:name]) do
    action :nothing
  end

  node[:_after_deploy_resources] ||= {}
  node[:_after_deploy_resources][resource] = params[:action]
end

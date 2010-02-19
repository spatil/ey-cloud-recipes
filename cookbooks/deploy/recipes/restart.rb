applications_to_deploy.each do |app, data|

  if any_app_needs_recipe?('mongrel')
    link "/data/#{app}/current/config/mongrel_cluster.yml" do
      to "/data/#{app}/shared/config/mongrel_cluster.yml"
    end
    execute "restart-mongrel-for-#{app}" do
      command "monit restart all -g #{app}"
    end
  end
  if any_app_needs_recipe?('unicorn')
    execute "restart-unicorn-for-#{app}" do
      command "/etc/init.d/unicorn_#{app} restart"
    end
  end

end

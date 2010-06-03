define :newrelic do

  app      = params[:name]
  app_name = "#{params[:env]} / #{app} (#{params[:framework_env]})"

  ey_cloud_report "newrelic #{app}" do
    message "configuring NewRelic RPM for #{app}"
  end

  template "/data/#{app}/shared/config/newrelic.yml" do
    source "newrelic.yml.erb"
    variables(
      :app   => app_name,
      :key   => params[:key],
      :seed  => params[:seed],
      :token => params[:token]
    )
  end

  if params[:symlink]
    directory_after_deploy "/data/#{app}/current/config"

    link_after_deploy "/data/#{app}/current/config/newrelic.yml" do
      to "/data/#{app}/shared/config/newrelic.yml"
    end
  end
end

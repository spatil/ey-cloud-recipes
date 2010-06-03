node.engineyard.apps.each do |app|
  if app.newrelic && node.engineyard.environment.newrelic_key
    newrelic app.name do
      env           node.engineyard.environment.name
      key           node.engineyard.environment.newrelic_key
      framework_env node.engineyard.environment.framework_env
      seed          node.engineyard.newrelic_seed
      token         node.engineyard.newrelic_token
      symlink       app.run_deploy
    end
  end
end

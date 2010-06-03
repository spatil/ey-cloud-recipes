gem_package "pg" do
  action :install
end

require_recipe 'ey-backup::postgres'

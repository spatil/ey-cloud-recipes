define :enable_package, :version => nil do
  name = params[:name]
  version = params[:version]
  full_name = name << ("-#{version}" if version)

  execute "unmask #{full_name}" do
    command "echo '=#{full_name}' >> /etc/portage/package.keywords/local"
    not_if "grep '=#{full_name}' /etc/portage/package.keywords/local"
  end
end

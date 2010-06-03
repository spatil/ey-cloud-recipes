define :ruby_install, :label => 'Ruby 1.8.6', :version => nil, :rubygems => '1.3.6' do
  label = params[:label]
  rubygems_version = params[:rubygems]

  ruby_version = case label
    when 'Ruby 1.8.6' then '1.8.6_p287-r2'
    when 'Ruby 1.8.7' then '1.8.7_p174'
    end

  enable_package 'dev-lang/ruby' do
    version ruby_version
  end

  ey_cloud_report "ruby install" do
    message "processing #{label}"
  end

  package 'dev-lang/ruby' do
    version ruby_version
  end

  ey_cloud_report "rubygems update" do
    message "processing Rubygems #{rubygems_version}"
  end

  bash "update rubygems to >= #{rubygems_version}" do
    code <<-EOH
      gem install rubygems-update -v #{rubygems_version}
      update_rubygems
    EOH

    not_if do
      Gem::Version.new(`gem -v`) >= Gem::Version.new(rubygems_version)
    end
  end
end

#
# Cookbook Name:: glassfish
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#


if_app_needs_recipe("glassfish") do |app,data,index|


  ey_cloud_report "glassfish" do
    message "processing glassfish"
  end
  
  package "sun-jdk" do
    action :install
  end
  
  execute "install-jruby" do
    command %Q{
      curl http://dist.codehaus.org/jruby/1.3.0RC2/jruby-bin-1.3.0RC2.tar.gz -O &&
      tar xvzf jruby-bin-1.3.0RC2.tar.gz &&
      mv jruby-1.3.0RC2 /usr/jruby &&
      rm jruby-bin-1.3.0RC2.tar.gz
    }
    
    not_if { File.directory?('/usr/jruby') }
  end
  
  execute "add-to-path" do
    command %Q{
      echo 'export PATH=$PATH:/usr/jruby/bin' >> /etc/profile
    }
    not_if "grep 'export PATH=$PATH:/usr/jruby/bin' /etc/profile"
  end
  
  execute "install-jgems" do
    command %Q{
      jruby -S gem install rails --no-rdoc --no-ri
    }
    not_if "jruby -S gem list | grep glassfish"
  end
  
  execute "start-glassfish" do
    command %Q{
      cd /data/#{app}/current &&
      glassfish -p 80 -e #{@node[:environment][:framework_env]} -d
    }
    not_if "pgrep java"
  end  

end

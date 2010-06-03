define :app_directory, :action => 'create', :root => '/data/' do
  case params[:action].to_sym
  when :create then
    %w( shared shared/config shared/pids shared/system releases ).each do |dir|
      directory "#{params[:root]}/#{params[:name]}/#{dir}" do
        owner params[:owner]
        group params[:group]
        mode 0755
      end
    end
  when :delete then
    directory "#{params[:root]}/#{params[:name]}/" do
      action :delete

      recursive true
    end
  end
end

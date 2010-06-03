define :wait_for_master_db, :password => nil do
  ey_cloud_report "waiting on database" do
    message 'verifying database connection'
  end

  ruby_block "wait for database" do
    block do
      ResourceGuard.ensure_mysql_running(params[:name], params[:password])
    end
  end
end

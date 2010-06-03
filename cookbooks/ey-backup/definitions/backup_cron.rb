define :backup_cron, :action => :create do
  model = params[:cron]

  cron params[:name] do
    action params[:action]

    minute   model.minute
    hour     model.hour
    day      model.day
    month    model.month
    weekday  model.weekday
    command  model.command
  end
end

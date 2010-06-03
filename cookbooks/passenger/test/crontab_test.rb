module PassengerRecipe
  class CrontabEntryTest < EY::Sommelier::TestCase
    scenario :epsilon

    def test_passenger_monitor_crontab_entries
      instance = instances(:solo)

      template.apps.each do |app|
        instance.ssh!(%{crontab -l | grep -e "^# Chef Name: passenger_monitor_#{app.name}$"})
      end
    end
  end

  class CrontabRemovalTest < EY::Sommelier::TestCase
    scenario :alpha
    #destructive!

    def test_deleted_app_removes_crontab_entries
      instance = instances(:solo)
      app = template.apps.first

      instance.ssh!(%{crontab -l | grep -e "^# Chef Name: passenger_monitor_#{app.name}$"})

      template.apps.reject! {|a| a == app }
      redeploy(:solo)

      instance.ssh(%{crontab -l | grep -e "^# Chef Name: passenger_monitor_#{app.name}$"}).exit_code.should.not.equal 0
    end
  end
end


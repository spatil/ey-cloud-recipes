module UnicornRecipe
  class MonitrcTest < EY::Sommelier::TestCase
    scenario :gamma

    def test_monit_entry_per_app
      instance = instances(:app_master)
      template.apps.each do |app|
        output = instance.ssh("monit status | grep 'unicorn_#{app.name}_worker' -A 3 | grep 'status'").stdout
        output.split("\n").each do |line|
          line.should =~ /(^\s*status\s+(running|PPID changed)$)|(^\s*monitoring status\s+monitored$)/
        end
      end
    end
  end

  class MonitStartTest < EY::Sommelier::TestCase
    scenario :gamma
    #destructive!

    def test_monit_starts_same_environment
      instance = instances(:app_master)
      instance.ssh!("ps aux | grep 'unicorn master' | grep -v grep | awk '{print $2}' | xargs kill")
      timeout = 40

      until ((instance.ssh("ps aux | grep 'unicorn master' | grep -v grep").exit_code == 0) || timeout == 0)
        sleep 5
        timeout -= 5
      end

      raise "Monit Timeout" if timeout == 0
    end
  end

  class MonitKillTest < EY::Sommelier::TestCase
    scenario :gamma
    #destructive!

    def test_monit_can_stop_unicorn_clusters
      instance = instances(:app_master)
      instance.ssh!("monit stop all -g unicorn_rack_app")
      sleep 30
      instance.ssh!("! ps aux | grep 'unicorn master' | grep -v grep")
    end
  end
end

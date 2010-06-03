module PostgresCoobook
  class ClientTest < EY::Sommelier::TestCase
    scenario :delta

    def test_pg_gem
      instance = instances(:app_master)

      instance.ssh!('gem list | grep pg')
    end

    def test_list_backups
      instance = instances(:app_master)
      instance.ssh!("eybackup -e postgresql -l rails_production")
    end
  end
end

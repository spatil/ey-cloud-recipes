module PostgresCoobook
  class ServerTest < EY::Sommelier::TestCase
    scenario :delta

    def test_postgresql_service_running
      instance = instances(:db_master)

      instance.ssh!('/etc/init.d/postgresql-8.3 status')
    end
  end
end

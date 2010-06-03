module RedisRecipe
  class SoloPackageTest < EY::Sommelier::TestCase
    scenario :alpha

    def test_redis_1_3_7_pre1
      instance = instances(:solo)
      instance.ssh!("eix -I dev-db/redis-1.3.7_pre1")
    end
  end

  class DatabasePackageTest < EY::Sommelier::TestCase
    scenario :beta

    def test_redis_1_3_7_pre1
      instance = instances(:db_master)
      instance.ssh!("eix -I dev-db/redis-1.3.7_pre1")
    end
  end
end

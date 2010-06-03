module EYBinRecipe
  class EYMonitScriptsTest < EY::Sommelier::TestCase
    scenario :alpha

    def test_redis_1_3_7_pre1
      instance = instances(:solo)
      instance.ssh!("eix -I sys-apps/ey-monit-scripts-0.16")
    end
  end
end

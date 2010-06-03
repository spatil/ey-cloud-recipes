module MemcachedRecipe
  class ConfigTest < EY::Sommelier::TestCase
    scenario :alpha

    def test_memcached_yml
      instance = instances(:solo)
      instance.ssh!('test -f /data/rails/shared/config/memcached.yml')
    end
  end
end

module RubyRecipe
  class VersionTest < EY::Sommelier::TestCase
    scenario :gamma

    def test_rubygems_1_3_6
      instances.each do |instance|
        instance.ssh!("ruby -v | grep 1.8.7")
      end
    end
  end
end

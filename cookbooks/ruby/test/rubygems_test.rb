module RubyRecipe
  class RubygemsTest < EY::Sommelier::TestCase
    scenario :alpha

    def test_rubygems_1_3_6
      instance = instances(:solo)

      instance.ssh!("gem -v | grep 1.3.6")
    end
  end
end

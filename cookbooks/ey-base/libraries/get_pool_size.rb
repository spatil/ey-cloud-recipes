class Chef
  class Recipe
    def get_pool_size
      case open("http://169.254.169.254/latest/meta-data/instance-type").read
      when "m1.small"
        8
      when "c1.medium"
        12
      when "m1.large"
        20
      when "m1.xlarge"
        40
      when "m2.2xlarge"
        80
      when "m2.4xlarge"
        160
      when "c1.xlarge"
        40
      end
    end

  end
end

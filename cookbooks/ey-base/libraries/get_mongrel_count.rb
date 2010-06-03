class Chef
  class Recipe
    def get_mongrel_count
      case open("http://169.254.169.254/latest/meta-data/instance-type").read
      when "m1.small"
        6
      when "c1.medium"
        8
      when "m1.large"
        16
      when "m1.xlarge"
        24
      when "m2.2xlarge"
        39
      when "m2.4xlarge"
        78
      when "c1.xlarge"
        20
      end
    end

  end
end

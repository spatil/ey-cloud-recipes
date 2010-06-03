class Chef
  class Node
    def default_collectd
      Collectd.defaults(ec2_instance_size)
    end

    class Collectd < Struct.new(:size)
      def self.defaults(size)
        new(size).defaults
      end

      def defaults
        { :load => load_defaults }
      end

      def load_defaults
        { :warning => vcpus * 4,
          :failure => vcpus * 10 }
      end

      def vcpus
        case size
        when "m1.small"
          1
        when "c1.medium", "m1.large"
          2
        when "m1.xlarge", "m2.2xlarge"
          4
        when "c1.xlarge", "m2.4xlarge"
          8
        else
          raise "Unknown instance size: #{ec2_instance_size.inspect}"
        end
      end
    end
  end
end

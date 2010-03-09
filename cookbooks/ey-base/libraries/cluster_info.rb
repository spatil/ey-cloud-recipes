class Chef
  class Node
    def cluster
      (app_master + app_slaves + util_servers + db_servers).flatten.uniq
    end

    def app_master
      if self["instance_role"] == "solo"
        ["localhost"]
      else
        Array(self["master_app_server"]["private_dns_name"])
      end
    end

    def app_slaves
      Array(self["members"])
    end

    def util_servers
      if self["utility_instances"]
        self["utility_instances"].map do |util|
          util["hostname"]
        end
      else
        []
      end
    end

    def db_servers
      db_master + db_slaves
    end

    def db_master
      Array(self["db_host"])
    end

    def db_slaves
      Array(self["db_slaves"])
    end
  end
end
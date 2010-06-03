class Chef
  class Recipe
    def find_app_services(app, service)
      results = Array.new
      node[:applications][app][:services].each do |svc|
        if svc[:resource] == service
          results << svc
        end
      end
      results
    end
    
    def find_app_service(app, service)
      node[:applications][app][:services].detect { |svc| svc[:resource] == service } || {}
    end
    
  end
end
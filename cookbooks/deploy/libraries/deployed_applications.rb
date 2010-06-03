class Chef
  class Recipe
    def applications_to_deploy
      node[:applications].select do |app, data|
        data[:run_deploy]
      end
    end
  end
end

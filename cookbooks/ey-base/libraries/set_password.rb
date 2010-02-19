class Chef
  class Recipe
    def set_password(user,pass)
      require 'open4'
      require 'expect'
      return Open4::popen4("passwd %s 2>&1" % user) do |pid, sin, sout, serr|
        2.times do
          sout.expect(/:/)
          sleep 0.1 
          sin.puts pass + "\n"
        end
      end
    end
  end
end    

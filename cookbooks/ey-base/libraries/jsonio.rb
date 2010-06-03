class JSONIO
  
  def initialize(file)
    @file = file
  end
  
  def to_json
    %Q{\"#{IO.read(@file).chomp}\"}
  end
end
class NameGen
  def initialize
    @vars = Hash.new
  end

  def gen(name)
    if @vars.has_key? name
      @vars[name] += 1
    else
      @vars[name] = 0
    end
    "#{name}_#{@vars[name]}"
  end
end

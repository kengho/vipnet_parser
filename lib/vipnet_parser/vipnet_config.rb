module VipnetParser
  class VipnetConfig
    def ==(other)
      res = true
      @props.each do |prop|
        res = res && self.send(prop.to_s) == other.send(prop.to_s)
      end
      res
    end
  end
end

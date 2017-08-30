module Geo3d
  class Vector
    def to_s_round(digits=2)
      to_a.compact.map{|i| i.round(digits)}.map {|v| sprintf("% #.2f", v)}.join(' ')
    end
  end
end


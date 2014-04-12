module Transit
  module Util
    def time_to_millis(time)
      (time.to_f * 1000.0).round
    end

    def time_from_millis(millis)
      Time.at(millis / 1000) + (millis % 1000) / 1000.0
    end

    module_function :time_to_millis, :time_from_millis
  end
end

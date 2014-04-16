module Transit
  module Util
    def date_time_to_millis(d)
      case d
      when Time
        (d.to_f * 1000.0).round
      else
        date_time_to_millis(d.to_time)
      end
    end

    def date_time_from_millis(millis)
      (Time.at(millis / 1000).utc + (millis % 1000) / 1000.0).to_datetime
    end

    module_function :date_time_to_millis, :date_time_from_millis
  end
end

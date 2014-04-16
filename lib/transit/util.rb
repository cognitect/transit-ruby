module Transit
  module Util
    def time_to_millis(time)
      (time.to_f * 1000.0).round
    end

    def date_time_to_millis(datetime)
      time_to_millis(datetime.to_time)
    end

    def date_to_millis(date)
      time_to_millis(date.to_time)
    end

    def time_from_millis(millis)
      Time.at(millis / 1000).utc + (millis % 1000) / 1000.0
    end

    module_function :time_to_millis, :date_time_to_millis, :date_to_millis, :time_from_millis
  end
end

module WaveFile
  # Calculates playback time given the number of samples and the sample rate.
  class Duration
    def initialize(sample_count, sample_rate)
      @sample_count = sample_count
      @sample_rate = sample_rate

      samples_per_millisecond = sample_rate / 1000.0
      samples_per_second = sample_rate
      samples_per_minute = samples_per_second * 60
      samples_per_hour = samples_per_minute * 60
      @hours, @minutes, @seconds, @milliseconds = 0, 0, 0, 0

      if(sample_count >= samples_per_hour)
        @hours = sample_count / samples_per_hour
        sample_count -= samples_per_hour * @hours
      end

      if(sample_count >= samples_per_minute)
        @minutes = sample_count / samples_per_minute
        sample_count -= samples_per_minute * @minutes
      end

      if(sample_count >= samples_per_second)
        @seconds = sample_count / samples_per_second
        sample_count -= samples_per_second * @seconds
      end

      @milliseconds = (sample_count / samples_per_millisecond).floor
    end

    attr_reader :sample_count, :sample_rate, :hours, :minutes, :seconds, :milliseconds
  end
end

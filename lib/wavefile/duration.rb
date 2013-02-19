module WaveFile
  # Calculates playback time given the number of samples and the sample rate.
  class Duration
    def initialize(sample_frame_count, sample_rate)
      @sample_frame_count = sample_frame_count
      @sample_rate = sample_rate

      sample_frames_per_millisecond = sample_rate / 1000.0
      sample_frames_per_second = sample_rate
      sample_frames_per_minute = sample_frames_per_second * 60
      sample_frames_per_hour = sample_frames_per_minute * 60
      @hours, @minutes, @seconds, @milliseconds = 0, 0, 0, 0

      if(sample_frame_count >= sample_frames_per_hour)
        @hours = sample_frame_count / sample_frames_per_hour
        sample_frame_count -= sample_frames_per_hour * @hours
      end

      if(sample_frame_count >= sample_frames_per_minute)
        @minutes = sample_frame_count / sample_frames_per_minute
        sample_frame_count -= sample_frames_per_minute * @minutes
      end

      if(sample_frame_count >= sample_frames_per_second)
        @seconds = sample_frame_count / sample_frames_per_second
        sample_frame_count -= sample_frames_per_second * @seconds
      end

      @milliseconds = (sample_frame_count / sample_frames_per_millisecond).floor
    end

    attr_reader :sample_frame_count, :sample_rate, :hours, :minutes, :seconds, :milliseconds
  end
end

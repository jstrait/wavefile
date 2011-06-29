module WaveFile
  class Info
    def initialize(file_name, raw_format_chunk, sample_count)
      @file_name = file_name
      @audio_format = raw_format_chunk[:audio_format]
      @channels = raw_format_chunk[:channels]
      @bits_per_sample = raw_format_chunk[:bits_per_sample]
      @sample_rate = raw_format_chunk[:sample_rate]
      @byte_rate = raw_format_chunk[:byte_rate]
      @block_align = raw_format_chunk[:block_align]
      @sample_count = sample_count
      @duration = calculate_duration()
    end

    attr_reader :file_name,
                :audio_format, :channels, :bits_per_sample, :sample_rate, :byte_rate, :block_align,
                :sample_count, :duration
  
  private

    # Calculates playback time given the number of samples and the sample rate.
    #
    # Returns a hash listing the number of hours, minutes, seconds, and milliseconds of
    # playback time.
    def calculate_duration()
      total_samples = @sample_count
      samples_per_millisecond = @sample_rate / 1000.0
      samples_per_second = @sample_rate
      samples_per_minute = samples_per_second * 60
      samples_per_hour = samples_per_minute * 60
      hours, minutes, seconds, milliseconds = 0, 0, 0, 0
      
      if(total_samples >= samples_per_hour)
        hours = total_samples / samples_per_hour
        total_samples -= samples_per_hour * hours
      end
      
      if(total_samples >= samples_per_minute)
        minutes = total_samples / samples_per_minute
        total_samples -= samples_per_minute * minutes
      end
      
      if(total_samples >= samples_per_second)
        seconds = total_samples / samples_per_second
        total_samples -= samples_per_second * seconds
      end
      
      milliseconds = (total_samples / samples_per_millisecond).floor
      
      @duration = { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
    end
  end
end

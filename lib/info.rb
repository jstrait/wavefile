module WaveFile
  class WaveFileInfo
    def initialize(file_name, format, sample_count)
      @file_name = file_name
      @channels = format.channels
      @bits_per_sample = format.bits_per_sample
      @sample_rate = format.sample_rate
      @byte_rate = format.byte_rate
      @block_align = format.block_align
      @sample_count = sample_count
      @duration = calculate_duration()
    end

    attr_reader :file_name,
                :channels,     :bits_per_sample, :sample_rate, :byte_rate, :block_align,
                :sample_count, :duration
  
  private

    def calculate_duration()
      total_samples = @sample_count
      samples_per_millisecond = sample_rate / 1000.0
      samples_per_second = sample_rate
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

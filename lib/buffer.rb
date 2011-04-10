module WaveFile
  class WaveFileBuffer
    def initialize(samples, format)
      @samples = samples
      @format = format
    end
    
    def convert(new_format)
      new_samples = convert_buffer(@samples.dup, @format, new_format)
      return WaveFileBuffer.new(new_samples, new_format)
    end

    def convert!(new_format)
      @samples = convert_buffer(@samples, @format, new_format)
      @format = new_format
      return self
    end

    def channels
      return @format.channels
    end

    def bits_per_sample
      return @format.bits_per_sample
    end

    def sample_rate
      return @format.sample_rate
    end

    attr_reader :samples

  private

    def convert_buffer(samples, old_format, new_format)
      return samples
    end
  end
end

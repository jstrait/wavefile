module WaveFile
  class WaveFileBuffer
    def initialize(samples, format)
      @samples = samples
      set_format(format)
    end

    def convert(new_format)
      return WaveFileBuffer.new(@samples, new_format)
    end

    def convert!(new_format)
      set_format(format)
      return self
    end

    attr_reader :samples, :channels, :bits_per_sample, :sample_rate

  private

    def set_format(format)
      @channels = format.channels
      @bits_per_sample = format.bits_per_sample
      @sample_rate = format.sample_rate
    end
  end
end

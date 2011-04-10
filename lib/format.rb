module WaveFile
  class WaveFileFormat
    def initialize(channels, bits_per_sample, sample_rate)
      self.channels=(channels)
      @bits_per_sample = bits_per_sample
      @sample_rate = sample_rate
    end

    def mono?()
      return @channels == 1
    end

    def stereo?()
      return @channels == 2
    end

    def byte_rate()
      return (@bits_per_sample / 8) * @sample_rate
    end

    def block_align()
      return (@bits_per_sample / 8) * @channels
    end

    def channels=(new_channels)
      if new_channels == :mono
        @channels = 1
      elsif new_channels == :stereo
        @channels = 2
      else
        @channels = new_channels
      end
    end

    attr_reader :channels
    attr_accessor :bits_per_sample, :sample_rate
  end
end

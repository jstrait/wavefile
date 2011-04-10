module WaveFile
  class WaveFileFormat
    def initialize(channels, bits_per_sample, sample_rate)
      if channels == :mono
        channels = 1
      end
      if channels == :stereo
        channels = 2
      end

      @channels = channels
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

    attr_accessor :channels, :bits_per_sample, :sample_rate
  end
end

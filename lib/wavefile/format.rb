module WaveFile
  class FormatError < RuntimeError; end

  class Format
    MAX_NUM_CHANNELS = 65535
    SUPPORTED_BITS_PER_SAMPLE = [8, 16, 32]

    def initialize(channels, bits_per_sample, sample_rate)
      self.channels=(channels)
      self.bits_per_sample=(bits_per_sample)
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
      validate_num_channels(new_channels)

      if new_channels == :mono
        @channels = 1
      elsif new_channels == :stereo
        @channels = 2
      else
        @channels = new_channels
      end
    end

    def bits_per_sample=(new_bits_per_sample)
      validate_bits_per_sample(new_bits_per_sample)
      @bits_per_sample = new_bits_per_sample
    end

    attr_reader :channels, :bits_per_sample
    attr_accessor :sample_rate
  
  private

    def validate_num_channels(candidate_num_channels)
      unless candidate_num_channels == :mono   ||
             candidate_num_channels == :stereo ||
             (1..MAX_NUM_CHANNELS) === candidate_num_channels
        raise FormatError, "Invalid number of channels. Must be between 1 and #{MAX_NUM_CHANNELS}."
      end
    end

    def validate_bits_per_sample(candidate_bits_per_sample)
      unless SUPPORTED_BITS_PER_SAMPLE.member?(candidate_bits_per_sample)
        raise FormatError,
              "Bits per sample of #{candidate_bits_per_sample} is unsupported. " +
              "Only #{SUPPORTED_BITS_PER_SAMPLE.inspect} are supported."
      end
    end
  end
end

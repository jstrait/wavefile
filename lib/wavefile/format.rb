module WaveFile
  class InvalidFormatError < StandardError; end

  class Format
    MAX_CHANNELS = 65535
    SUPPORTED_BITS_PER_SAMPLE = [8, 16, 32]
    MAX_SAMPLE_RATE = 4_294_967_296

    def initialize(channels, bits_per_sample, sample_rate)
      channels = canonicalize_channels(channels)
      validate_channels(channels)
      validate_bits_per_sample(bits_per_sample)
      validate_sample_rate(sample_rate)

      @channels = channels
      @bits_per_sample = bits_per_sample
      @sample_rate = sample_rate
      @block_align = (@bits_per_sample / 8) * @channels
      @byte_rate = @block_align * @sample_rate
    end

    def mono?()
      return @channels == 1
    end

    def stereo?()
      return @channels == 2
    end

    attr_reader :channels, :bits_per_sample, :sample_rate, :block_align, :byte_rate
  
  private

    def canonicalize_channels(channels)
      if channels == :mono
        return 1
      elsif channels == :stereo
        return 2
      else
        return channels
      end
    end

    def validate_channels(candidate_channels)
      unless (1..MAX_CHANNELS) === candidate_channels
        raise InvalidFormatError, "Invalid number of channels. Must be between 1 and #{MAX_CHANNELS}."
      end
    end

    def validate_bits_per_sample(candidate_bits_per_sample)
      unless SUPPORTED_BITS_PER_SAMPLE.member?(candidate_bits_per_sample)
        raise InvalidFormatError,
              "Bits per sample of #{candidate_bits_per_sample} is unsupported. " +
              "Only #{SUPPORTED_BITS_PER_SAMPLE.inspect} are supported."
      end
    end

    def validate_sample_rate(candidate_sample_rate)
      unless (1..MAX_SAMPLE_RATE) === candidate_sample_rate
        raise InvalidFormatError, "Invalid sample rate. Must be between 1 and #{MAX_SAMPLE_RATE}"
      end
    end
  end
end

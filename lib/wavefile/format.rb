module WaveFile
  class FormatError < RuntimeError; end

  class Format
    MAX_CHANNELS = 65535
    SUPPORTED_BITS_PER_SAMPLE = [8, 16, 32]

    def initialize(channels, bits_per_sample, sample_rate)
      validate_channels(channels)
      validate_bits_per_sample(bits_per_sample)

      @channels = canonicalize_channels(channels)
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

    attr_reader :channels, :bits_per_sample, :sample_rate, :byte_rate, :block_align
  
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
      unless candidate_channels == :mono   ||
             candidate_channels == :stereo ||
             (1..MAX_CHANNELS) === candidate_channels
        raise FormatError, "Invalid number of channels. Must be between 1 and #{MAX_CHANNELS}."
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

module WaveFile
  # Public: Error that is raised when a file is not in a format supported by this Gem.
  # For example, because it's a valid Wave file whose format is not supported by
  # this Gem. Or, because it's a not a valid Wave file period.
  class FormatError < StandardError; end

  # Public: Error that is raised when constructing a Format instance that is not valid,
  # trying to read from a file that is not a wave file, or trying to read from a file
  # that is not valid according to the wave file spec.
  class InvalidFormatError < FormatError; end

  # Public: Error that is raised when trying to read from a valid wave file that has its sample data
  # stored in a format that Reader doesn't understand.
  class UnsupportedFormatError < FormatError; end

  # Public: Represents information about the data format for a Wave file, such as number of
  # channels, bits per sample, sample rate, and so forth. A Format instance is used
  # by Reader to indicate what format to read samples out as, and by Writer to
  # indicate what format to write samples as.
  class Format

    # Public: Constructs a new immutable Format.
    #
    # channels - The number of channels in the format. Can either be an Integer
    #            (e.g. 1, 2, 3) or the symbols +:mono+ (equivalent to 1) or
    #            +:stereo+ (equivalent to 2).
    # format_code - A symbol indicating the format of each sample. Consists of
    #               two parts: a format code, and the bits per sample. The valid
    #               values are +:pcm_8+, +:pcm_16+, +:pcm_24+, +:pcm_32+, +:float_32+,
    #               +:float_64+, and +:float+ (equivalent to +:float_32+)
    # sample_rate - The number of samples per second, such as 44100
    # speaker_mapping - An optional array which indicates which speaker each channel should be
    #                   mapped to. Each value in the array should be one of these values:
    #                   +:front_left+, +:front_right+, +:front_center+, +:low_frequency+, +:back_left+,
    #                   +:back_right+, +:front_left_of_center+, +:front_right_of_center+,
    #                   +:back_center+, +:side_left+, +:side_right+, +:top_center+, +:top_front_left+,
    #                   +:top_front_center+, +:top_front_right+, +:top_back_left+, +:top_back_center+,
    #                   +:top_back_right+. Each value should only appear once, and the channels
    #                   must follow the ordering above. For example, [:front_center, :back_left]
    #                   is a valid speaker mapping, but [:back_left, :front_center] is not.
    #                   If a given channel should not be mapped to a specific speaker, the
    #                   value :undefined can be used. If this field is omitted, a default
    #                   value for the given number of channels. For example, if there are 2
    #                   channels, this will be set to [:front_left, :front_right].
    #
    # Examples
    #
    #   format = Format.new(1, :pcm_16, 44100)
    #   format = Format.new(:mono, :pcm_16, 44100)  # Equivalent to above
    #
    #   format = Format.new(:stereo, :float_32, 44100)
    #   format = Format.new(:stereo, :float, 44100)  # Equivalent to above
    #
    #   format = Format.new(2, :pcm_16, 44100, speaker_mapping: [:front_right, :front_center])
    #
    #   # Channels should explicitly not be mapped to particular speakers
    #   # (otherwise, if no speaker_mapping set, it will be set to a default
    #   # value for the number of channels).
    #   format = Format.new(2, :pcm_16, 44100, speaker_mapping: [:undefined, :undefined])
    #
    #   # Will result in InvalidFormatError, because speakers are defined in
    #   # invalid order
    #   format = Format.new(2, :pcm_16, 44100, speaker_mapping: [:front_right, :front_left])
    #
    #   # speaker_mapping will be set to [:front_left, :undefined, :undefined],
    #   # because channels without a speaker mapping will be mapped to :undefined
    #   format = Format.new(3, :pcm_16, 44100, speaker_mapping: [:front_left])
    #
    # Raises InvalidFormatError if the given arguments are invalid.
    def initialize(channels, format_code, sample_rate, speaker_mapping: nil)
      channels = normalize_channels(channels)

      validate_channels(channels)
      validate_format_code(format_code)
      validate_sample_rate(sample_rate)

      sample_format, bits_per_sample = normalize_format_code(format_code)

      speaker_mapping = normalize_speaker_mapping(channels, speaker_mapping)
      validate_speaker_mapping(channels, speaker_mapping)

      @channels = channels
      @sample_format = sample_format
      @bits_per_sample = bits_per_sample
      @sample_rate = sample_rate
      @block_align = (@bits_per_sample / 8) * @channels
      @byte_rate = @block_align * @sample_rate
      @speaker_mapping = speaker_mapping
    end

    # Public: Returns true if the format has 1 channel, false otherwise.
    def mono?
      @channels == 1
    end

    # Public: Returns true if the format has 2 channels, false otherwise.
    def stereo?
      @channels == 2
    end

    # Public: Returns the number of channels, such as 1 or 2. This will always return a
    # Integer, even if the number of channels is specified with a symbol (e.g. :mono)
    # in the constructor.
    attr_reader :channels

    # Public: Returns a symbol indicating the sample format, such as :pcm or :float
    attr_reader :sample_format

    # Public: Returns the number of bits per sample, such as 8, 16, 24, 32, or 64.
    attr_reader :bits_per_sample

    # Public: Returns the number of samples per second, such as 44100.
    attr_reader :sample_rate

    # Public: Returns the number of bytes in each sample frame. For example, in a 16-bit stereo file,
    # this will be 4 (2 bytes for each 16-bit sample, times 2 channels).
    attr_reader :block_align

    # Public: Returns the number of bytes contained in 1 second of sample data.
    # Is equivalent to block_align * sample_rate.
    attr_reader :byte_rate

    # Public: Returns the mapping of each channel to a speaker.
    attr_reader :speaker_mapping

  private

    # Internal
    VALID_CHANNEL_RANGE     = 1..65535    # :nodoc:
    # Internal
    VALID_SAMPLE_RATE_RANGE = 1..4_294_967_296    # :nodoc:

    # Internal
    SUPPORTED_FORMAT_CODES = [:pcm_8, :pcm_16, :pcm_24, :pcm_32, :float, :float_32, :float_64].freeze    # :nodoc:

    # Internal
    def normalize_channels(channels)
      if channels == :mono
        return 1
      elsif channels == :stereo
        return 2
      else
        return channels
      end
    end

    # Internal
    def normalize_format_code(format_code)
      if format_code == :float
        [:float, 32]
      else
        sample_format, bits_per_sample = format_code.to_s.split("_")
        [sample_format.to_sym, bits_per_sample.to_i]
      end
    end

    # Internal
    def normalize_speaker_mapping(channels, speaker_mapping)
      if speaker_mapping.nil?
        speaker_mapping = default_speaker_mapping(channels)
      elsif !speaker_mapping.is_a?(Array)
        return speaker_mapping
      else
        speaker_mapping = speaker_mapping.dup
      end

      if speaker_mapping.length < channels
        speaker_mapping += [:undefined] * (channels - speaker_mapping.length)
      end

      speaker_mapping.freeze
    end

    # Internal
    def default_speaker_mapping(channels)
      # These default mappings determined from these sources:
      #
      # See https://docs.microsoft.com/en-us/windows-hardware/drivers/audio/extensible-wave-format-descriptors
      # This article says to use the `front_center` speaker for mono files when using WAVE_FORMAT_EXTENSIBLE
      #
      # https://msdn.microsoft.com/en-us/library/windows/desktop/dd390971(v=vs.85).aspx
      #
      # https://xiph.org/flac/format.html#frame_header
      if channels == 1  # Mono
        [:front_center]
      elsif channels == 2  # Stereo
        [:front_left, :front_right]
      elsif channels == 3
        [:front_left, :front_right, :front_center]
      elsif channels == 4  # Quad
        [:front_left, :front_right, :back_left, :back_right]
      elsif channels == 5
        [:front_left, :front_right, :front_center, :back_left, :back_right]
      elsif channels == 6  # 5.1
        [:front_left, :front_right, :front_center, :low_frequency, :back_left, :back_right]
      elsif channels == 7
        [:front_left, :front_right, :front_center, :low_frequency, :back_center, :side_left, :side_right]
      elsif channels == 8  # 7.1
        [:front_left, :front_right, :front_center, :low_frequency, :back_left, :back_right, :front_left_of_center, :front_right_of_center]
      elsif channels <= UnvalidatedFormat::SPEAKER_POSITIONS.length
        UnvalidatedFormat::SPEAKER_POSITIONS[0...channels]
      else
        UnvalidatedFormat::SPEAKER_POSITIONS
      end
    end

    # Internal
    def validate_channels(candidate_channels)
      unless candidate_channels.is_a?(Integer) && VALID_CHANNEL_RANGE === candidate_channels
        raise InvalidFormatError,
              "Invalid number of channels: `#{candidate_channels}`. Must be an Integer between #{VALID_CHANNEL_RANGE.min} and #{VALID_CHANNEL_RANGE.max}."
      end
    end

    # Internal
    def validate_format_code(candidate_format_code)
      unless SUPPORTED_FORMAT_CODES.include? candidate_format_code
        raise InvalidFormatError,
              "Invalid sample format: `#{candidate_format_code}`. Must be one of: #{SUPPORTED_FORMAT_CODES.inspect}"
      end
    end

    # Internal
    def validate_sample_rate(candidate_sample_rate)
      unless candidate_sample_rate.is_a?(Integer) && VALID_SAMPLE_RATE_RANGE === candidate_sample_rate
        raise InvalidFormatError,
              "Invalid sample rate: `#{candidate_sample_rate}`. Must be an Integer between #{VALID_SAMPLE_RATE_RANGE.min} and #{VALID_SAMPLE_RATE_RANGE.max}"
      end
    end

    # Internal
    def validate_speaker_mapping(channels, candidate_speaker_mapping)
      if candidate_speaker_mapping.is_a?(Array) && candidate_speaker_mapping.length == channels
        speaker_mapping_without_invalid_speakers = UnvalidatedFormat::SPEAKER_POSITIONS & candidate_speaker_mapping
        if speaker_mapping_without_invalid_speakers.length < channels
          speaker_mapping_without_invalid_speakers += [:undefined] * (channels - speaker_mapping_without_invalid_speakers.length)
        end

        if speaker_mapping_without_invalid_speakers == candidate_speaker_mapping
          return
        end
      end

      raise InvalidFormatError,
            "Invalid speaker_mapping: `#{candidate_speaker_mapping.inspect}`. Should be an array the same size as the number of channels, containing either :undefined or these known speakers: #{UnvalidatedFormat::SPEAKER_POSITIONS.inspect}. Each defined speaker must come before any of the ones after it in the master list, and all :undefined speakers must come after the last defined speaker."
    end
  end
end

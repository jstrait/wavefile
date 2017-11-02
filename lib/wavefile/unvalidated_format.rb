module WaveFile
  # Represents information about the data format for a Wave file, such as number of
  # channels, bits per sample, sample rate, and so forth. A Format instance is used
  # by Reader to indicate what format to read samples out as, and by Writer to
  # indicate what format to write samples as.
  #
  # This class is immutable - once a new Format is constructed, it can't be modified.
  class UnvalidatedFormat < Format    # :nodoc:
    # Constructs a new immutable UnvalidatedFormat.
    def initialize(fields)
      @audio_format = fields[:audio_format]
      @sub_audio_format_guid = fields[:sub_audio_format_guid]
      @channels = fields[:channels]
      @sample_rate = fields[:sample_rate]
      @byte_rate = fields[:byte_rate]
      @block_align = fields[:block_align]
      @bits_per_sample = fields[:bits_per_sample]
      @speaker_mapping = parse_speaker_mapping(fields[:speaker_mapping])
      @valid_bits_per_sample = fields[:valid_bits_per_sample]
    end

    attr_reader :audio_format, :sub_audio_format_guid, :valid_bits_per_sample

    def to_validated_format
      if @sub_audio_format_guid.nil?
        audio_format_code = @audio_format
      else
        if @sub_audio_format_guid == SUB_FORMAT_GUID_PCM
          audio_format_code = 1
        elsif @sub_audio_format_guid == SUB_FORMAT_GUID_FLOAT
          audio_format_code = 3
        else
          audio_format_code = nil
        end
      end

      if @valid_bits_per_sample
        if @valid_bits_per_sample != @bits_per_sample
          raise UnsupportedFormatError,
                "Sample container size (#{@bits_per_sample}) and valid bits per sample (#{@valid_bits_per_sample}) " +
                "differ."
        end

        bits_per_sample = @valid_bits_per_sample
      else
        bits_per_sample = @bits_per_sample
      end

      sample_format = "#{FORMAT_CODES.invert[audio_format_code]}_#{bits_per_sample}".to_sym

      Format.new(@channels, sample_format, @sample_rate, speaker_mapping: @speaker_mapping)
    end

  private

    # Internal
    def parse_speaker_mapping(bit_field)
      return nil if bit_field.nil?

      mapping = []
      speaker_index = 0

      while (mapping.length < @channels) && (speaker_index < SPEAKER_POSITIONS.length)
        if bit_field & (2 ** speaker_index) != 0
          mapping << SPEAKER_POSITIONS[speaker_index]
        end

        speaker_index += 1
      end

      mapping.fill(:undefined, mapping.length, @channels - mapping.length)
      mapping.freeze
    end

    # Internal
    SPEAKER_POSITIONS = [
      :front_left,
      :front_right,
      :front_center,
      :low_frequency,
      :back_left,
      :back_right,
      :front_left_of_center,
      :front_right_of_center,
      :back_center,
      :side_left,
      :side_right,
      :top_center,
      :top_front_left,
      :top_front_center,
      :top_front_right,
      :top_back_left,
      :top_back_center,
      :top_back_right,
    ]
  end
end

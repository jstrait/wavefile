module WaveFile
  # Public: Represents an SMPTE timecode: https://en.wikipedia.org/wiki/SMPTE_timecode
  #         If a *.wav file has a `smpl` chunk, then Reader.SamplerInfo.smpte_offset
  #         will return an instance of this class.
  class SMPTETimecode
    def initialize(hours:, minutes:, seconds:, frames:)
      validate_8_bit_signed_integer_field(hours, "hours")
      validate_8_bit_unsigned_integer_field(minutes, "minutes")
      validate_8_bit_unsigned_integer_field(seconds, "seconds")
      validate_8_bit_unsigned_integer_field(frames, "frames")

      @hours = hours
      @minutes = minutes
      @seconds = seconds
      @frames = frames
    end

    attr_reader :hours
    attr_reader :minutes
    attr_reader :seconds
    attr_reader :frames
  end

  private

  VALID_8_BIT_UNSIGNED_INTEGER_RANGE = 0..255
  VALID_8_BIT_SIGNED_INTEGER_RANGE = -128..127

  def validate_8_bit_unsigned_integer_field(candidate, field_name)
    unless candidate.is_a?(Integer) && VALID_8_BIT_UNSIGNED_INTEGER_RANGE === candidate
      raise InvalidFormatError,
            "Invalid `#{field_name}` value: `#{candidate}`. Must be an Integer between #{VALID_8_BIT_UNSIGNED_INTEGER_RANGE.min} and #{VALID_8_BIT_UNSIGNED_INTEGER_RANGE.max}"
    end
  end

  def validate_8_bit_signed_integer_field(candidate, field_name)
    unless candidate.is_a?(Integer) && VALID_8_BIT_SIGNED_INTEGER_RANGE === candidate
      raise InvalidFormatError,
            "Invalid `#{field_name}` value: `#{candidate}`. Must be an Integer between #{VALID_8_BIT_SIGNED_INTEGER_RANGE.min} and #{VALID_8_BIT_SIGNED_INTEGER_RANGE.max}"
    end
  end
end

module WaveFile
  # Public: Provides a way to indicate the data about sampler loop points
  #         in a file's "smpl" chunk. That is, information about how a sampler
  #         could loop between a sample range while playing this *.wav as a note.
  #         If a *.wav file contains a "smpl" chunk, then Reader.sample_info.loops
  #         will return an array of SamplerLoop objects with the relevant info.
  class SamplerLoop
    # Public: Constructs a new SamplerLoop instance.
    #
    # id - A numeric ID which identifies the specific loop.
    # type - Indicates which direction the loop should run. Should either be one of the symbols
    #        +:forward+, +:alternating+, +:backward+, or a positive Integer. If an Integer, then 0 will
    #        be normalized to +:forward+, 1 to +:alternating+, 2 to +:backward+.
    # start_sample_frame - The first sample frame in the loop.
    # end_sample_frame - The last sample frame in the loop.
    # fraction - A Float between 0.0 and 1.0 which specifies a fraction of a sample at which to loop.
    #            This allows a loop to be fine tuned at a resolution finer than one sample.
    # play_count - The number of times to loop. 0 means infinitely.
    #
    # Raises InvalidFormatError if the given arguments are invalid.
    def initialize(id:, type:, start_sample_frame:, end_sample_frame:, fraction:, play_count:)
      type = normalize_type(type)

      validate_32_bit_integer_field(id, "id")
      validate_loop_type(type)
      validate_32_bit_integer_field(start_sample_frame, "start_sample_frame")
      validate_32_bit_integer_field(end_sample_frame, "end_sample_frame")
      validate_fraction(fraction)
      validate_32_bit_integer_field(play_count, "play_count")

      @id = id
      @type = type
      @start_sample_frame = start_sample_frame
      @end_sample_frame = end_sample_frame
      @fraction = fraction
      @play_count = play_count
    end

    # Public: Returns the ID of the specific Loop
    attr_reader :id

    # Public: Returns a symbol indicating which direction the loop should run. The possible values
    #         are :forward, :alternating, :backward, or a positive Integer.
    attr_reader :type

    # Public: Returns the first sample frame of the loop.
    attr_reader :start_sample_frame

    # Public: Returns the last sample frame of the loop.
    attr_reader :end_sample_frame

    # Public: A value between 0.0 and 1.0 which specifies a fraction of a sample at which to loop.
    #         This allows a loop to be fine tuned at a resolution finer than one sample.
    attr_reader :fraction

    # Public: Returns the number of times to loop. 0 means infinitely.
    attr_reader :play_count

    private

    VALID_32_BIT_INTEGER_RANGE = 0..4_294_967_295    # :nodoc:
    VALID_LOOP_TYPES = [:forward, :alternating, :backward].freeze    # :nodoc:

    # Internal
    def normalize_type(type)
      if !type.is_a?(Integer)
        return type
      end

      if type == 0
        :forward
      elsif type == 1
        :alternating
      elsif type == 2
        :backward
      else
        type
      end
    end

    # Internal
    def validate_32_bit_integer_field(candidate, field_name)
      unless candidate.is_a?(Integer) && VALID_32_BIT_INTEGER_RANGE === candidate
        raise InvalidFormatError,
              "Invalid `#{field_name}` value: `#{candidate}`. Must be an Integer between #{VALID_32_BIT_INTEGER_RANGE.min} and #{VALID_32_BIT_INTEGER_RANGE.max}"
      end
    end

    # Internal
    def validate_loop_type(candidate)
      unless VALID_LOOP_TYPES.include?(candidate) || (candidate.is_a?(Integer) && VALID_32_BIT_INTEGER_RANGE === candidate)
        raise InvalidFormatError,
              "Invalid `type` value: `#{candidate}`. Must be an Integer between #{VALID_32_BIT_INTEGER_RANGE.min} and #{VALID_32_BIT_INTEGER_RANGE.max} or one of #{VALID_LOOP_TYPES}"
      end
    end

    # Internal
    def validate_fraction(candidate)
      unless (candidate.is_a?(Integer) || candidate.is_a?(Float)) && candidate >= 0.0 && candidate < 1.0
        raise InvalidFormatError,
              "Invalid `fraction` value: `#{candidate}`. Must be >= 0.0 and < 1.0"
      end
    end
  end
end

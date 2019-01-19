module WaveFile
  # Public: Error that is raised when constructing a SamplerLoop instance that is invalid.
  #         "Invalid" means that one or more fields have a value that can't be encoded in the
  #         field inside a *.wav file. For example, there's no way to encode "-23" as a value
  #         for the start_sample_frame field. However, this error _won't_ be raised for values
  #         that can be encoded, but aren't semantically correct. For example, it's possible
  #         to set the start_sample_frame or end_sample_frame fields to values that don't
  #         correspond to the actual sample frame range of the file. This error _won't_ be
  #         raised for "encodeable but not semantically valid" field values.
  class InvalidSamplerLoopError < StandardError; end

  # Public: Provides a way to indicate the data about sampler loop points
  #         in a file's "smpl" chunk. That is, information about how a sampler
  #         could loop between a sample range while playing this *.wav as a note.
  #         If a *.wav file contains a "smpl" chunk, then Reader.sampler_info.loops
  #         will return an array of SamplerLoop objects with the relevant info.
  class SamplerLoop
    # Public: Constructs a new SamplerLoop instance.
    #
    # id - A numeric ID which identifies the specific loop. Should be an Integer 0 or greater.
    # type - Indicates which direction the loop should run. Should either be one of the symbols
    #        +:forward+, +:alternating+, +:backward+, or a positive Integer. If an Integer, then 0 will
    #        be normalized to +:forward+, 1 to +:alternating+, 2 to +:backward+. Integer values 3 or
    #        greater are allowed by the *.wav file spec, but don't necessarily have a defined meaning.
    # start_sample_frame - The first sample frame in the loop.
    # end_sample_frame - The last sample frame in the loop.
    # fraction - A Float >= 0.0 and < 1.0 which specifies a fraction of a sample at which to start
    #            the loop. This allows a loop start to be fine tuned at a resolution finer than one sample.
    # play_count - The number of times to loop. Can be an Integer 0 or greater, or Float::INFINITY.
    #              A value of 0 will be normalized to Float::INFINITY, because in the file format a
    #              value of 0 means to repeat the loop indefinitely.
    #
    # Raises InvalidSamplerLoopError if the given arguments can't be written to a *.wav file.
    def initialize(id: required("id"),
                  type: required("type"),
                  start_sample_frame: required("start_sample_frame"),
                  end_sample_frame: required("end_sample_frame"),
                  fraction: required("fraction"),
                  play_count: required("play_count"))
      type = normalize_type(type)
      if play_count == 0
        play_count = Float::INFINITY
      end

      validate_32_bit_integer_field(id, "id")
      validate_loop_type(type)
      validate_32_bit_integer_field(start_sample_frame, "start_sample_frame")
      validate_32_bit_integer_field(end_sample_frame, "end_sample_frame")
      validate_fraction(fraction)
      validate_play_count(play_count)

      @id = id
      @type = type
      @start_sample_frame = start_sample_frame
      @end_sample_frame = end_sample_frame
      @fraction = fraction
      @play_count = play_count
    end

    # Public: Returns a numeric ID which identifies the specific loop
    attr_reader :id

    # Public: Returns a symbol indicating which direction the loop should run. The possible values
    #         are :forward, :alternating, :backward, or a positive Integer. Integer values 3 or greater
    #         are allowed by the *.wav file spec, but don't necessarily have a defined meaning.
    attr_reader :type

    # Public: Returns the first sample frame of the loop.
    attr_reader :start_sample_frame

    # Public: Returns the last sample frame of the loop.
    attr_reader :end_sample_frame

    # Public: A value >= 0.0 and < 1.0 which specifies a fraction of a sample at which to loop.
    #         This allows a loop to be fine tuned at a resolution finer than one sample.
    attr_reader :fraction

    # Public: Returns the number of times to loop. Will be an Integer 1 or greater, or Float::INFINITY.
    attr_reader :play_count

    private

    VALID_32_BIT_INTEGER_RANGE = 0..4_294_967_295    # :nodoc:
    VALID_LOOP_TYPES = [:forward, :alternating, :backward].freeze    # :nodoc:

    def required(keyword)
      raise ArgumentError.new("missing keyword: #{keyword}")
    end

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
        raise InvalidSamplerLoopError,
              "Invalid `#{field_name}` value: `#{candidate}`. Must be an Integer between #{VALID_32_BIT_INTEGER_RANGE.min} and #{VALID_32_BIT_INTEGER_RANGE.max}"
      end
    end

    # Internal
    def validate_loop_type(candidate)
      unless VALID_LOOP_TYPES.include?(candidate) || (candidate.is_a?(Integer) && VALID_32_BIT_INTEGER_RANGE === candidate)
        raise InvalidSamplerLoopError,
              "Invalid `type` value: `#{candidate}`. Must be an Integer between #{VALID_32_BIT_INTEGER_RANGE.min} and #{VALID_32_BIT_INTEGER_RANGE.max} or one of #{VALID_LOOP_TYPES}"
      end
    end

    # Internal
    def validate_fraction(candidate)
      unless (candidate.is_a?(Integer) || candidate.is_a?(Float)) && candidate >= 0.0 && candidate < 1.0
        raise InvalidSamplerLoopError,
              "Invalid `fraction` value: `#{candidate}`. Must be >= 0.0 and < 1.0"
      end
    end

    # Internal
    def validate_play_count(candidate)
      unless candidate == Float::INFINITY || (candidate.is_a?(Integer) && VALID_32_BIT_INTEGER_RANGE === candidate)
        raise InvalidSamplerLoopError,
              "Invalid `type` value: `#{candidate}`. Must be Float::INFINITY or an Integer between #{VALID_32_BIT_INTEGER_RANGE.min} and #{VALID_32_BIT_INTEGER_RANGE.max}"
      end
    end
  end
end

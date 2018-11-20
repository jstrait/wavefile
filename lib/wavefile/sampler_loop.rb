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
    #        be normalized to +:forward+, 1 to +:alternating+, 2 to +:backward+, and 3 or greater will
    #        be normalized to +:unknown+.
    # start_sample_frame - The first sample frame in the loop.
    # end_sample_frame - The last sample frame in the loop.
    # fraction - A Float between 0.0 and 1.0 which specifies a fraction of a sample at which to loop.
    #            This allows a loop to be fine tuned at a resolution finer than one sample.
    # play_count - The number of times to loop. 0 means infinitely.
    #
    # Raises InvalidFormatError if the given arguments are invalid.
    def initialize(id:, type:, start_sample_frame:, end_sample_frame:, fraction:, play_count:)
      type = normalize_type(type)

      validate_id(id)
      validate_loop_type(type)
      validate_start_sample_frame(start_sample_frame)
      validate_end_sample_frame(end_sample_frame)
      validate_fraction(fraction)
      validate_play_count(play_count)

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
    #         are :forward, :alternating, :backward, or :unknown.
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

    VALID_ID_RANGE = 0..4_294_967_295    # :nodoc:
    VALID_TYPE_RANGE = 0..4_294_967_295    # :nodoc:
    VALID_LOOP_TYPES = [:forward, :alternating, :backward, :unknown].freeze    # :nodoc:
    VALID_SAMPLE_FRAME_RANGE = 0..4_294_967_295    # :nodoc:
    VALID_PLAY_COUNT_RANGE = 0..4_294_967_295    # :nodoc:

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
      elsif VALID_TYPE_RANGE === type
        :unknown
      else
        type
      end
    end

    # Internal
    def validate_id(candidate_id)
      unless candidate_id.is_a?(Integer) && VALID_ID_RANGE === candidate_id
        raise InvalidFormatError,
              "Invalid sample loop ID: `#{candidate_id}`. Must be an Integer between #{VALID_ID_RANGE.min} and #{VALID_ID_RANGE.max}"
      end
    end

    # Internal
    def validate_loop_type(candidate_type)
      unless VALID_LOOP_TYPES.include?(candidate_type)
        raise InvalidFormatError,
              "Invalid sample loop type: `#{candidate_type}`. Must be an Integer between #{VALID_TYPE_RANGE.min} and #{VALID_TYPE_RANGE.max} or one of #{VALID_LOOP_TYPES}"
      end
    end

    # Internal
    def validate_start_sample_frame(candidate_start_sample_frame)
      unless candidate_start_sample_frame.is_a?(Integer) && VALID_SAMPLE_FRAME_RANGE === candidate_start_sample_frame
        raise InvalidFormatError,
              "Invalid start sample frame: `#{candidate_start_sample_frame}`. Must be an Integer between #{VALID_SAMPLE_FRAME_RANGE.min} and #{VALID_SAMPLE_FRAME_RANGE.max}"
      end
    end

    # Internal
    def validate_end_sample_frame(candidate_end_sample_frame)
      unless candidate_end_sample_frame.is_a?(Integer) && VALID_SAMPLE_FRAME_RANGE === candidate_end_sample_frame
        raise InvalidFormatError,
              "Invalid end sample frame: `#{candidate_end_sample_frame}`. Must be an Integer between #{VALID_SAMPLE_FRAME_RANGE.min} and #{VALID_SAMPLE_FRAME_RANGE.max}"
      end
    end

    # Internal
    def validate_fraction(candidate_fraction)
      unless (candidate_fraction.is_a?(Integer) || candidate_fraction.is_a?(Float)) && candidate_fraction >= 0.0 && candidate_fraction < 1.0
        raise InvalidFormatError,
              "Invalid sample loop fraction: `#{candidate_fraction}`. Must be >= 0.0 and < 1.0"
      end
    end

    # Internal
    def validate_play_count(candidate_play_count)
      unless candidate_play_count.is_a?(Integer) && VALID_PLAY_COUNT_RANGE === candidate_play_count
        raise InvalidFormatError,
              "Invalid play count: `#{candidate_play_count}`. Must be an Integer between #{VALID_PLAY_COUNT_RANGE.min} and #{VALID_PLAY_COUNT_RANGE.max}"
      end
    end
  end
end

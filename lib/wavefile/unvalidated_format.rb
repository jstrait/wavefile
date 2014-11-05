module WaveFile
  # Represents information about the data format for a Wave file, such as number of 
  # channels, bits per sample, sample rate, and so forth. A Format instance is used 
  # by Reader to indicate what format to read samples out as, and by Writer to 
  # indicate what format to write samples as.
  #
  # This class is immutable - once a new Format is constructed, it can't be modified.
  class UnvalidatedFormat    # :nodoc:
    # Constructs a new immutable UnvalidatedFormat.
    def initialize(fields)
      @audio_format = fields[:audio_format]
      @channels = fields[:channels]
      @sample_rate = fields[:sample_rate]
      @byte_rate = fields[:byte_rate]
      @block_align = fields[:block_align]
      @bits_per_sample = fields[:bits_per_sample]
    end

    # Returns true if the format has 1 channel, false otherwise.
    def mono?
      @channels == 1
    end

    # Returns true if the format has 2 channels, false otherwise.
    def stereo?
      @channels == 2
    end

    # Returns the number of channels, such as 1 or 2. This will always return a 
    # Fixnum, even if the number of channels is specified with a symbol (e.g. :mono) 
    # in the constructor.
    attr_reader :channels

    # Returns a number indicating the sample format, such as 1 (PCM) or 3 (Float)
    attr_reader :audio_format

    # Returns the number of bits per sample, such as 8, 16, 24, 32, or 64.
    attr_reader :bits_per_sample

    # Returns the number of samples per second, such as 44100.
    attr_reader :sample_rate

    # Returns the number of bytes in each sample frame. For example, in a 16-bit stereo file, 
    # this will be 4 (2 bytes for each 16-bit sample, times 2 channels).
    attr_reader :block_align

    # Returns the number of bytes contained in 1 second of sample data. 
    # Is equivalent to block_align * sample_rate.
    attr_reader :byte_rate
  end
end


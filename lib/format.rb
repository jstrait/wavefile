module WaveFile
  class WaveFileFormat
    def initialize(channels, bits_per_sample, sample_rate, interleaving)
      @channels = channels
      @bits_per_sample = bits_per_sample
      @sample_rate = sample_rate
      @interleaving = interleaving
    end

    def byte_rate()
      return (@bits_per_sample / 8) * @sample_rate
    end

    def block_align()
      return (@bits_per_sample / 8) * @channels
    end

    attr_accessor :channels, :bits_per_sample, :sample_rate, :interleaving
  end
end

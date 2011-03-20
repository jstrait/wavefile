module WaveFile
  class WaveFileBuffer
    def initialize(samples, format)
      @samples = samples
      @format = format
    end
    
    def convert(new_format)
      new_samples = convert_buffer(@samples.dup, @format, new_format)
      return WaveFileBuffer.new(new_samples, new_format)
    end

    def convert!(new_format)
      @samples = convert_buffer(@samples, @format, new_format)
      @format = new_format
      return self
    end

    def channels
      return @format.channels
    end

    def bits_per_sample
      return @format.bits_per_sample
    end

    def sample_rate
      return @format.sample_rate
    end

    attr_reader :samples

  private

    def convert_buffer(samples, old_format, new_format)
      if old_format.interleaving != :interleaved && new_format.interleaving == :interleaved
        samples = interleave_samples(samples)
      end

      samples = convert_channels(samples, old_format.channels, new_format.channels)
      samples = convert_bits_per_sample(samples, old_format.bits_per_sample, new_format.bits_per_sample)

      if new_format.interleaving != :interleaved && old_format.interleaving == :interleaved
        if new_format.channels > 1
          samples = deinterleave_samples(samples, new_format.channels)
        end
      end

      return samples
    end

    def interleave_samples(samples)
      return samples.flatten
    end

    def deinterleave_samples(samples, channels)
      new_samples = []
      i = 0
      while i < (samples.length) do
        new_samples += [samples[i...(i += channels)]]
      end

      return new_samples
    end

    # Only works on interleaved samples. It is expected that convert_buffer() will
    # guarantee that samples passed to this method are interleaved.
    def convert_channels(samples, old_channels, new_channels)
      return samples
    end

    def convert_bits_per_sample(samples, old_bits_per_sample, new_bits_per_sample)
      return samples
    end
  end
end

module WaveFile
  class Buffer
    def initialize(samples, format)
      @samples = samples
      @format = format
    end
    
    def convert(new_format)
      new_samples = convert_buffer(@samples.dup, @format, new_format)
      return Buffer.new(new_samples, new_format)
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
      new_samples = samples.dup
      
      unless old_format.channels == new_format.channels
        new_samples = convert_buffer_channels(new_samples, old_format.channels, new_format.channels)
      end

      @format = new_format
      
      return new_samples
    end

    def convert_buffer_channels(samples, old_channels, new_channels)
      # The cases of mono -> stereo and vice-versa are handled specially,
      # because those conversion methods are faster than the general methods,
      # and the large majority of wave files are expected to be either mono or stereo.
      if old_channels == 1 && new_channels == 2
        samples.map! {|sample| [sample, sample]}
      elsif old_channels == 2 && new_channels == 1
        samples.map! {|sample| (sample[0] + sample[1]) / 2}
      elsif old_channels == 1 && new_channels >= 2
        samples.map! {|sample| [].fill(sample, 0, new_channels)}
      elsif old_channels >= 2 && new_channels == 1
        samples.map! {|sample| sample.inject(0) {|sub_sample, sum| sum + sub_sample } / old_channels }
      elsif old_channels > 2 && new_channels == 2
        samples.map! {|sample| [sample[0], sample[1]]}
      else
        raise "Conversion of sample data from #{old_channels} channels to #{new_channels} channels is unsupported"
      end
    
      return samples
    end
  end
end

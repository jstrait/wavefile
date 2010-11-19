class WaveFileInfo
  def initialize(file_name)
  end
end

class WaveFileFormat
  def initialize(channels, bits_per_sample, sample_rate)
    @channels = channels
    @bits_per_sample = @bits_per_sample
    @sample_rate = sample_rate
  end

  def byte_rate()
    return (@bits_per_sample / 8) * sample_rate
  end

  def block_align()
    return (@bits_per_sample / 8) * @num_channels
  end

  attr_accessor :channels, :bits_per_sample, :sample_rate
end

class WaveFileReader
  def initialize(format)
  end

  def read(buffer_size)
  end
end

class WaveFileWriter
  def initialize(file_name, format)
  end

  def write(sample_data)
  end

  def close()
  end
end

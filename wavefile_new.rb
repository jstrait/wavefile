module WaveFile
  CHUNK_ID = "RIFF"
  FORMAT = "WAVE"
  FORMAT_CHUNK_ID = "fmt "
  SUB_CHUNK1_SIZE = 16
  PCM = 1
  DATA_CHUNK_ID = "data"
  HEADER_SIZE = 36
  PACK_CODES = {8 => "C*", 16 => "s*", 32 => "V*"}

  class WaveFileInfo
    def initialize(file_name)
    end
  end

  class WaveFileFormat
    def initialize(channels, bits_per_sample, sample_rate)
      @channels = channels
      @bits_per_sample = bits_per_sample
      @sample_rate = sample_rate
    end

    def byte_rate()
      return (@bits_per_sample / 8) * sample_rate
    end

    def block_align()
      return (@bits_per_sample / 8) * @channels
    end

    attr_accessor :channels, :bits_per_sample, :sample_rate
  end

  class WaveFileBuffer
    def initialize(samples, format)
      @samples = samples
      @channels = format.channels
      @bits_per_sample = format.bits_per_sample
      @sample_rate = format.sample_rate
    end

    def convert(format)
      return self
    end

    attr_reader :samples, :channels, :bits_per_sample, :sample_rate
  end

  class WaveFileReader
    def initialize(format)
    end

    def read(buffer_size)
    end
  end

  class WaveFileWriter
    def initialize(file_name, format)
      @file = File.open(file_name, "w")
      @format = format

      @sample_count = 0
      @pack_code = PACK_CODES[format.bits_per_sample]
      write_header(0)
    end

    def write(buffer)
      converted_buffer = buffer.convert(@format)
      samples = converted_buffer.samples

      @file.syswrite(samples.pack(@pack_code))
      @sample_count += samples.length
    end

    def close()
      @file.sysseek(0)
      write_header(@sample_count)
      
      @file.close()
    end

  private

    def write_header(sample_data_size)
      header = CHUNK_ID
      header += [HEADER_SIZE + sample_data_size].pack("V")
      header += FORMAT
      header += FORMAT_CHUNK_ID
      header += [SUB_CHUNK1_SIZE].pack("V")
      header += [PCM].pack("v")
      header += [@format.channels].pack("v")
      header += [@format.sample_rate].pack("V")
      header += [@format.byte_rate].pack("V")
      header += [@format.block_align].pack("v")
      header += [@format.bits_per_sample].pack("v")
      header += DATA_CHUNK_ID
      header += [sample_data_size].pack("V")

      @file.syswrite(header)
    end
  end
end


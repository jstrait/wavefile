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
    def initialize(file_name, format, sample_count)
      @file_name = file_name
      @channels = format.channels
      @bits_per_sample = format.bits_per_sample
      @sample_rate = format.sample_rate
      @byte_rate = format.byte_rate
      @block_align = format.block_align
      @sample_count = sample_count
      @duration = calculate_duration()
    end

    attr_reader :file_name,
                :channels,     :bits_per_sample, :sample_rate, :byte_rate, :block_align,
                :sample_count, :duration
  
  private

    def calculate_duration()
      total_samples = @sample_count
      samples_per_millisecond = sample_rate / 1000.0
      samples_per_second = sample_rate
      samples_per_minute = samples_per_second * 60
      samples_per_hour = samples_per_minute * 60
      hours, minutes, seconds, milliseconds = 0, 0, 0, 0
      
      if(total_samples >= samples_per_hour)
        hours = total_samples / samples_per_hour
        total_samples -= samples_per_hour * hours
      end
      
      if(total_samples >= samples_per_minute)
        minutes = total_samples / samples_per_minute
        total_samples -= samples_per_minute * minutes
      end
      
      if(total_samples >= samples_per_second)
        seconds = total_samples / samples_per_second
        total_samples -= samples_per_second * seconds
      end
      
      milliseconds = (total_samples / samples_per_millisecond).floor
      
      @duration = { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
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
      set_format(format)
    end

    def convert(new_format)
      return WaveFileBuffer.new(@samples, format)
    end

    def convert!(new_format)
      set_format(format)
      return self
    end

    attr_reader :samples, :channels, :bits_per_sample, :sample_rate

  private

    def set_format(format)
      @channels = format.channels
      @bits_per_sample = format.bits_per_sample
      @sample_rate = format.sample_rate
    end
  end

  class WaveFileReader
    def initialize(file_name)
      @file_name = file_name
      @file = File.open(file_name, "r")

      read_header()
    end

    def read(buffer_size, format=@format)
      samples = @file.sysread(buffer_size).unpack(PACK_CODES[format.bits_per_sample])

      buffer = WaveFileBuffer.new(samples, @format)
      return buffer.convert(format)
    end

    def close()
      @file.close()
    end

    attr_reader :info

  private
  
    def read_header()
      header = {}
    
      # Read RIFF header
      riff_header = @file.sysread(12).unpack("a4Va4")
      header[:chunk_id] = riff_header[0]
      header[:chunk_size] = riff_header[1]
      header[:format] = riff_header[2]
    
      # Read format subchunk
      header[:sub_chunk1_id], header[:sub_chunk1_size] = read_to_chunk(FORMAT_CHUNK_ID)
      format_subchunk_str = @file.sysread(header[:sub_chunk1_size])
      format_subchunk = format_subchunk_str.unpack("vvVVvv")  # Any extra parameters are ignored
      header[:audio_format] = format_subchunk[0]
      header[:channels] = format_subchunk[1]
      header[:sample_rate] = format_subchunk[2]
      header[:byte_rate] = format_subchunk[3]
      header[:block_align] = format_subchunk[4]
      header[:bits_per_sample] = format_subchunk[5]
    
      # Read data subchunk
      header[:sub_chunk2_id], header[:sub_chunk2_size] = read_to_chunk(DATA_CHUNK_ID)
   
      validate_header(header)
    
      sample_count = header[:sub_chunk2_size] / header[:block_align]

      @format = WaveFileFormat.new(header[:channels], header[:bits_per_sample], header[:sample_rate])
      @info = WaveFileInfo.new(@file_name, @format, sample_count)
    end

    def read_to_chunk(expected_chunk_id)
      chunk_id = @file.sysread(4)
      chunk_size = @file.sysread(4).unpack("V")[0]

      while chunk_id != expected_chunk_id
        # Skip chunk
        file.sysread(chunk_size)
        
        chunk_id = @file.sysread(4)
        chunk_size = @file.sysread(4).unpack("V")[0]
      end
      
      return chunk_id, chunk_size
    end

    def validate_header(header)
      return true
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
      samples = buffer.convert(@format).samples

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


module WaveFile
  class WaveFileReader
    def initialize(file_name, format=nil)
      @file_name = file_name
      @file = File.open(file_name, "r")

      read_header()
      
      if format == nil
        @output_format = @native_format
      else
        @output_format = format
      end
    end

    def read(buffer_size)
      samples = @file.sysread(buffer_size * @native_format.block_align).unpack(PACK_CODES[@native_format.bits_per_sample])

      buffer = WaveFileBuffer.new(samples, @native_format)
      return buffer.convert(@output_format)
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
      header[:sub_chunk1_id], header[:sub_chunk1_size] = read_to_chunk(CHUNK_IDS[:format])
      format_subchunk_str = @file.sysread(header[:sub_chunk1_size])
      format_subchunk = format_subchunk_str.unpack("vvVVvv")  # Any extra parameters are ignored
      header[:audio_format] = format_subchunk[0]
      header[:channels] = format_subchunk[1]
      header[:sample_rate] = format_subchunk[2]
      header[:byte_rate] = format_subchunk[3]
      header[:block_align] = format_subchunk[4]
      header[:bits_per_sample] = format_subchunk[5]
    
      # Read data subchunk
      header[:sub_chunk2_id], header[:sub_chunk2_size] = read_to_chunk(CHUNK_IDS[:data])
   
      validate_header(header)
    
      sample_count = header[:sub_chunk2_size] / header[:block_align]

      @native_format = WaveFileFormat.new(header[:channels], header[:bits_per_sample], header[:sample_rate])
      @info = WaveFileInfo.new(@file_name, @native_format, sample_count)
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
end

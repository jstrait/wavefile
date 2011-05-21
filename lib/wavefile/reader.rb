module WaveFile
  class Reader
    def initialize(file_name, format=nil)
      @file_name = file_name
      @file = File.open(file_name, "rb")

      read_header()
      
      if format == nil
        @output_format = @native_format
      else
        @output_format = format
      end
    end

    def each_buffer(buffer_size)
      begin
        while true do
          yield(read(buffer_size))
        end
      rescue EOFError
        close()
      end
    end

    def read(buffer_size)
      samples = @file.sysread(buffer_size * @native_format.block_align).unpack(PACK_CODES[@native_format.bits_per_sample])

      if @native_format.channels > 1
        num_multichannel_samples = samples.length / @native_format.channels
        multichannel_data = Array.new(num_multichannel_samples)
      
        if(@native_format.channels == 2)
          # Files with more than 2 channels are expected to be rare, so if there are 2 channels
          # using a faster specific algorithm instead of a general one.
          num_multichannel_samples.times {|i| multichannel_data[i] = [samples.pop(), samples.pop()].reverse!() }
        else
          # General algorithm that works for any number of channels, 2 or greater.
          num_multichannel_samples.times do |i|
            sample = Array.new(@native_format.channels)
            num_channels.times {|j| sample[j] = samples.pop() }
            multichannel_data[i] = sample.reverse!()
          end
        end

        samples = multichannel_data.reverse!()
      end

      buffer = Buffer.new(samples, @native_format)
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

      @native_format = Format.new(header[:channels], header[:bits_per_sample], header[:sample_rate])
      @info = Info.new(@file_name, @native_format, sample_count)
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

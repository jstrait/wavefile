module WaveFile
  class UnsupportedFormatError < StandardError; end

  class Reader
    def initialize(file_name, format=nil)
      @file_name = file_name
      @file = File.open(file_name, "rb")

      read_header()
      
      if format == nil
        @format = @native_format
      else
        @format = format
      end

      if block_given?
        yield(self)
        close()
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
      return buffer.convert(@format)
    end

    def close()
      @file.close()
    end

    attr_reader :file_name, :format, :info

  private
    FORMAT_CHUNK_MINIMUM_SIZE = 16

    VALID_FORMAT_CHUNK_SIZES = [16, 18, 40]
    FORMAT_CHUNK_SIZE_TO_EXTENSION_SIZE = {16 => nil, 18 => 0, 40 => 22}

    def read_header()
      # Read RIFF header
      begin
        riff_header = {}
        riff_header[:chunk_id],
        riff_header[:chunk_size],
        riff_header[:riff_format] = @file.sysread(12).unpack("a4Va4")
        validate_riff_header(riff_header)
      rescue EOFError
        raise UnsupportedFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "It is empty."
      end

      # Read format chunk
      format_chunk = {}
      format_chunk[:chunk_id], format_chunk[:chunk_size] = read_to_chunk(CHUNK_IDS[:format])

      if format_chunk[:chunk_size] < FORMAT_CHUNK_MINIMUM_SIZE
        raise UnsupportedFormatError, "TODO"
      end

      format_chunk_str = @file.sysread(format_chunk[:chunk_size])
      format_chunk[:audio_format],
      format_chunk[:channels],
      format_chunk[:sample_rate],
      format_chunk[:byte_rate],
      format_chunk[:block_align],
      format_chunk[:bits_per_sample] = format_chunk_str.slice!(FORMAT_CHUNK_MINIMUM_SIZE).unpack("vvVVvv")

      if format_chunk[:chunk_size] > FORMAT_CHUNK_MINIMUM_SIZE
        format_chunk[:extension_size] = format_chunk_str.slice!(2).unpack("v")

        if format_chunk[:extension_size] == nil
          raise UnsupportedFormatError, "TODO"
        end

        if format_chunk[:extension_size] != format_chunk_str.length
          raise UnsupportedFormatError, "TODO"
        end

        # TODO: Parse the extension
      end

      # Read data subchunk
      data_chunk = {}
      data_chunk[:data_chunk_id], data_chunk[:data_chunk_size] = read_to_chunk(CHUNK_IDS[:data])
   
      sample_count = data_chunk[:data_chunk_size] / format_chunk[:block_align]

      @native_format = Format.new(format_chunk[:channels], format_chunk[:bits_per_sample], format_chunk[:sample_rate])
      @info = Info.new(@file_name, @native_format, sample_count)
    end

    def read_to_chunk(expected_chunk_id)
      chunk_id = @file.sysread(4)
      chunk_size = @file.sysread(4).unpack("V")[0]

      while chunk_id != expected_chunk_id
        # Skip chunk
        @file.sysread(chunk_size)
        
        chunk_id = @file.sysread(4)
        chunk_size = @file.sysread(4).unpack("V")[0]
      end
      
      return chunk_id, chunk_size
    end

    def validate_riff_header(riff_header)
      unless riff_header[:chunk_id] == CHUNK_IDS[:header]
        raise UnsupportedFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "Expected chunk ID '#{CHUNK_IDS[:header]}', but was '#{riff_header[:chunk_id]}'"
      end

      unless riff_header[:riff_format] == WAVEFILE_FORMAT_CODE
        raise UnsupportedFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_header[:riff_format]}'"
      end
    end
  end
end

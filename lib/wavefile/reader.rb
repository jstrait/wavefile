module WaveFile
  class InvalidFormatError < StandardError; end

  class Reader
    def initialize(file_name, format=nil)
      @file_name = file_name
      @file = File.open(file_name, "rb")

      raw_format_chunk, sample_count = read_until_data_chunk()
      @sample_count = sample_count
      # Make sure we can actually read the file
      validate_format(raw_format_chunk)

      if format == nil
        @format = Format.new(raw_format_chunk[:channels], raw_format_chunk[:bits_per_sample], raw_format_chunk[:sample_rate])
      else
        @format = format
      end

      if block_given?
        yield(self)
        close()
      end
    end

    def self.info(file_name)
      file = File.open(file_name, "rb")
      raw_format_chunk, sample_count = read_until_data_chunk(file)
      file.close()

      return Info.new(file_name, raw_format_chunk, sample_count)
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

    attr_reader :file_name, :format

  private
    FORMAT_CHUNK_MINIMUM_SIZE = 16

    def read_until_data_chunk()
      read_riff_chunk_header()

      begin
        chunk_id = @file.sysread(4)
        chunk_size = @file.sysread(4).unpack("V")[0]
        while chunk_id != CHUNK_IDS[:data]
          if chunk_id == CHUNK_IDS[:format]
            format_chunk = parse_format_chunk(chunk_size, @file.sysread(chunk_size))
          else
            # Other chunk types besides the format chunk are ignored. This may change in the future.
            @file.sysread(chunk_size)
          end

          chunk_id = @file.sysread(4)
          chunk_size = @file.sysread(4).unpack("V")[0]
        end
      rescue EOFError
        raise InvalidFormatError, "TODO"
      end

      if format_chunk == nil
        raise InvalidFormatError, "File either has no format chunk, or it comes after the data chunk"
      end

      sample_count = chunk_size / format_chunk[:block_align]

      return format_chunk, sample_count
    end

    def read_riff_chunk_header()
      begin
        riff_header = {}
        riff_header[:chunk_id],
        riff_header[:chunk_size],
        riff_header[:riff_format] = @file.sysread(12).unpack("a4Va4")
      rescue EOFError
        raise InvalidFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "It is empty."
      end

      unless riff_header[:chunk_id] == CHUNK_IDS[:header]
        raise InvalidFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "Expected chunk ID '#{CHUNK_IDS[:header]}', but was '#{riff_header[:chunk_id]}'"
      end

      unless riff_header[:riff_format] == WAVEFILE_FORMAT_CODE
        raise InvalidFormatError,
              "File '#{@file_name}' is not a supported wave file. " +
              "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_header[:riff_format]}'"
      end
    end

    def parse_format_chunk(chunk_size, raw_chunk_data)
      if chunk_size < FORMAT_CHUNK_MINIMUM_SIZE
        raise InvalidFormatError, "TODO"
      end

      begin
        format_chunk_str = @file.sysread(format_chunk[:chunk_size])
      rescue
        raise InvalidFormatError, "TODO"
      end
      format_chunk[:audio_format],
      format_chunk[:channels],
      format_chunk[:sample_rate],
      format_chunk[:byte_rate],
      format_chunk[:block_align],
      format_chunk[:bits_per_sample] = format_chunk_str.slice!(0...FORMAT_CHUNK_MINIMUM_SIZE).unpack("vvVVvv")

      if format_chunk[:chunk_size] > FORMAT_CHUNK_MINIMUM_SIZE
        format_chunk[:extension_size] = format_chunk_str.slice!(0...2).unpack("v")

        if format_chunk[:extension_size] == nil
          raise InvalidFormatError, "TODO"
        end

        if format_chunk[:extension_size] != format_chunk_str.length
          raise InvalidFormatError, "TODO"
        end

        # TODO: Parse the extension
      end

      return format_chunk
    end

    def validate_format_chunk(raw_format_chunk)
      return true
    end
  end
end

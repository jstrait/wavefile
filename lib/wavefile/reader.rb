module WaveFile
  class InvalidFormatError < StandardError; end

  class UnsupportedFormatError < StandardError; end

  class Reader
    def initialize(file_name, format=nil)
      @file_name = file_name
      @file = File.open(file_name, "rb")

      raw_format_chunk, sample_count = HeaderReader.new(@file, @file_name).read_until_data_chunk()
      @sample_count = sample_count
      # Make file is in a format we can actually read
      validate_format_chunk(raw_format_chunk)

      @native_format = Format.new(raw_format_chunk[:channels],
                                  raw_format_chunk[:bits_per_sample],
                                  raw_format_chunk[:sample_rate])
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

    def self.info(file_name)
      file = File.open(file_name, "rb")
      raw_format_chunk, sample_count = HeaderReader.new(file, file_name).read_until_data_chunk()
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

    def validate_format_chunk(raw_format_chunk)
      # :byte_rate and :block_align are not checked to make sure that match :channels/:sample_rate/bits_per_sample
      # because this library doesn't use them.

      unless raw_format_chunk[:audio_format] == PCM
        raise UnsupportedFormatError, "Audio format is #{raw_format_chunk[:audio_format]}, " +
                                      "but only format code 1 (i.e. PCM) is supported."
      end

      unless Format::SUPPORTED_BITS_PER_SAMPLE.include?(raw_format_chunk[:bits_per_sample])
        raise UnsupportedFormatError, "Bits per sample is #{raw_format_chunk[:bits_per_sample]}, " +
                                      "but only #{Format::SUPPORTED_BITS_PER_SAMPLE.inspect} are supported."
      end

      unless raw_format_chunk[:channels] > 0
        raise UnsupportedFormatError, "Number of channels is #{raw_format_chunk[:channels]}, " +
                                      "but only #{Format::MIN_CHANNELS}-#{Format::MAX_CHANNELS} are supported."
      end

      unless raw_format_chunk[:sample_rate] > 0
        raise UnsupportedFormatError, "Sample rate is #{raw_format_chunk[:channels]}, " +
                                      "but only #{Format::MIN_SAMPLE_RATE}-#{Format::MAX_SAMPLE_RATE} are supported."
      end
    end
  end


  class HeaderReader
    RIFF_CHUNK_HEADER_SIZE = 12
    FORMAT_CHUNK_MINIMUM_SIZE = 16

    def initialize(file, file_name)
      @file = file
      @file_name = file_name
    end

    def read_until_data_chunk()
      read_riff_chunk()

      begin
        chunk_id = @file.sysread(4)
        chunk_size = @file.sysread(4).unpack("V")[0]
        while chunk_id != CHUNK_IDS[:data]
          if chunk_id == CHUNK_IDS[:format]
            format_chunk = read_format_chunk(chunk_id, chunk_size)
          else
            # Other chunk types besides the format chunk are ignored. This may change in the future.
            @file.sysread(chunk_size)
          end

          chunk_id = @file.sysread(4)
          chunk_size = @file.sysread(4).unpack("V")[0]
        end
      rescue EOFError
        raise_error InvalidFormatError, "It doesn't have a data chunk."
      end

      if format_chunk == nil
        raise_error InvalidFormatError, "The format chunk is either missing, or it comes after the data chunk."
      end

      sample_count = chunk_size / format_chunk[:block_align]

      return format_chunk, sample_count
    end

  private

    def read_riff_chunk()
      riff_header = {}
      riff_header[:chunk_id],
      riff_header[:chunk_size],
      riff_header[:riff_format] = read_chunk_body(CHUNK_IDS[:header], RIFF_CHUNK_HEADER_SIZE).unpack("a4Va4")

      unless riff_header[:chunk_id] == CHUNK_IDS[:header]
        raise_error InvalidFormatError, "Expected chunk ID '#{CHUNK_IDS[:header]}', but was '#{riff_header[:chunk_id]}'"
      end

      unless riff_header[:riff_format] == WAVEFILE_FORMAT_CODE
        raise_error InvalidFormatError, "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_header[:riff_format]}'"
      end

      return riff_header
    end

    def read_format_chunk(chunk_id, chunk_size)
      if chunk_size < FORMAT_CHUNK_MINIMUM_SIZE
        raise_error InvalidFormatError, "The format chunk is incomplete."
      end

      raw_bytes = read_chunk_body(CHUNK_IDS[:format], chunk_size)

      format_chunk = {}
      format_chunk[:audio_format],
      format_chunk[:channels],
      format_chunk[:sample_rate],
      format_chunk[:byte_rate],
      format_chunk[:block_align],
      format_chunk[:bits_per_sample] = raw_bytes.slice!(0...FORMAT_CHUNK_MINIMUM_SIZE).unpack("vvVVvv")

      if chunk_size > FORMAT_CHUNK_MINIMUM_SIZE
        format_chunk[:extension_size] = raw_bytes.slice!(0...2).unpack("v").first

        if format_chunk[:extension_size] == nil
          raise_error InvalidFormatError, "The format chunk is missing an expected extension."
        end

        if format_chunk[:extension_size] != raw_bytes.length
          raise_error InvalidFormatError, "The format chunk extension is shorter than expected."
        end

        # TODO: Parse the extension
      end

      return format_chunk
    end

    def read_chunk_body(chunk_id, chunk_size)
      begin
        return @file.sysread(chunk_size)
      rescue EOFError
        raise_error InvalidFormatError, "The #{chunk_id} chunk has incomplete data."
      end
    end

    def raise_error(exception_class, message)
      raise exception_class, "File '#{@file_name}' is not a supported wave file. #{message}"
    end
  end
end

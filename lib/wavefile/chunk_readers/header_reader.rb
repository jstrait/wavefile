module WaveFile
  module ChunkReaders
    # Used to read the RIFF chunks in a wave file up until the data chunk. Thus is can be used
    # to open a wave file and "queue it up" to the start of the actual sample data, as well as
    # extract information out of pre-data chunks, such as the format chunk.
    class HeaderReader    # :nodoc:
      RIFF_CHUNK_HEADER_SIZE = 12
      FORMAT_CHUNK_MINIMUM_SIZE = 16

      def initialize(file, file_name)
        @file = file
        @file_name = file_name
      end

      def read_until_data_chunk
        read_riff_chunk

        begin
          chunk_id = @file.sysread(4)
          chunk_size = @file.sysread(4).unpack(UNSIGNED_INT_32).first
          while chunk_id != CHUNK_IDS[:data]
            if chunk_id == CHUNK_IDS[:format]
              native_format = read_format_chunk(chunk_id, chunk_size)
            else
              # The RIFF specification requires that each chunk be aligned to an even number of bytes,
              # even if the byte count is an odd number.
              #
              # See http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/Docs/riffmci.pdf, page 11.
              if chunk_size.odd?
                chunk_size += 1
              end

              # Other chunk types besides the format chunk are ignored. This may change in the future.
              read_chunk_body(chunk_id, chunk_size)
            end

            chunk_id = @file.sysread(4)
            chunk_size = @file.sysread(4).unpack(UNSIGNED_INT_32).first
          end
        rescue EOFError
          raise_error InvalidFormatError, "It doesn't have a data chunk."
        end

        if native_format == nil
          raise_error InvalidFormatError, "The format chunk is either missing, or it comes after the data chunk."
        end

        sample_frame_count = chunk_size / native_format.block_align

        return native_format, sample_frame_count
      end

    private

      def read_riff_chunk
        riff_header = {}
        riff_header[:chunk_id],
        riff_header[:chunk_size],
        riff_header[:riff_format] = read_chunk_body(CHUNK_IDS[:riff], RIFF_CHUNK_HEADER_SIZE).unpack("a4Va4")

        unless riff_header[:chunk_id] == CHUNK_IDS[:riff]
          raise_error InvalidFormatError, "Expected chunk ID '#{CHUNK_IDS[:riff]}', but was '#{riff_header[:chunk_id]}'"
        end

        unless riff_header[:riff_format] == WAVEFILE_FORMAT_CODE
          raise_error InvalidFormatError, "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_header[:riff_format]}'"
        end

        riff_header
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
          format_chunk[:extension_size] = raw_bytes.slice!(0...2).unpack(UNSIGNED_INT_16).first

          if format_chunk[:extension_size] == nil
            raise_error InvalidFormatError, "The format chunk is missing an expected extension."
          end

          if format_chunk[:extension_size] != raw_bytes.length
            raise_error InvalidFormatError, "The format chunk extension is shorter than expected."
          end

          # TODO: Parse the extension
        end

        UnvalidatedFormat.new(format_chunk)
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
end

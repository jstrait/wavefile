module WaveFile
  module ChunkReaders
    # Internal: Used to read the RIFF chunks in a wave file up until the data chunk. Thus it
    # can be used to open a wave file and "queue it up" to the start of the actual sample data,
    # as well as extract information out of pre-data chunks, such as the format chunk.
    class RiffReader    # :nodoc:
      def initialize(io, format=nil)
        @io = io

        read_until_data_chunk(format)
      end

      attr_reader :native_format, :data_chunk_reader, :sample_chunk

    private

      def read_until_data_chunk(format)
        chunk_id, riff_chunk_size = read_chunk_header
        unless chunk_id == CHUNK_IDS[:riff]
          raise_error InvalidFormatError, "Expected chunk ID '#{CHUNK_IDS[:riff]}', but was '#{chunk_id}'"
        end

        end_of_file_pos = @io.pos + riff_chunk_size

        RiffChunkReader.new(@io, riff_chunk_size).read

        data_chunk_seek_pos = nil
        data_chunk_size = nil
        data_chunk_is_final_chunk = nil

        loop do
          chunk_id, chunk_size = read_chunk_header

          case chunk_id
          when CHUNK_IDS[:format]
            if data_chunk_seek_pos != nil
              raise_error InvalidFormatError, "The format chunk is after the data chunk; it must come before."
            end

            @native_format = FormatChunkReader.new(@io, chunk_size).read
          when CHUNK_IDS[:sample]
            @sample_chunk = SampleChunkReader.new(@io, chunk_size).read
          when CHUNK_IDS[:data]
            data_chunk_seek_pos = @io.pos
            data_chunk_size = chunk_size

            # Only look for chunks after the data chunk if there are enough bytes
            # left in the file for that to be possible.
            start_of_next_chunk_pos = (@io.pos + data_chunk_size)
            start_of_next_chunk_pos += 1 if chunk_size.odd?
            if start_of_next_chunk_pos < end_of_file_pos
              @io.seek(data_chunk_seek_pos + chunk_size, IO::SEEK_SET)
            else
              data_chunk_is_final_chunk = true
            end
          else
            # Unsupported chunk types are ignored
            @io.read(chunk_size)
          end

          # The RIFF specification requires that each chunk be aligned to an even number of bytes,
          # even if the byte count is an odd number.
          #
          # See http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/Docs/riffmci.pdf, page 11.
          if chunk_size.odd?
            @io.read(1)
          end

          break if @io.pos >= end_of_file_pos || data_chunk_is_final_chunk
        end

        if @native_format == nil
          raise_error InvalidFormatError, "Format chunk couldn't be found."
        end

        if data_chunk_seek_pos.nil?
          raise_error InvalidFormatError, "Data chunk couldn't be found."
        end

        if @io.pos != data_chunk_seek_pos
          @io.seek(data_chunk_seek_pos, IO::SEEK_SET)
        end
        @data_chunk_reader = DataChunkReader.new(@io, data_chunk_size, @native_format, format)
      end

      def read_chunk_header
        chunk_id = @io.read(4)
        chunk_size = @io.read(4)

        unless chunk_size.nil?
          chunk_size = chunk_size.unpack(UNSIGNED_INT_32).first
        end

        if chunk_size.nil?
          raise_error InvalidFormatError, "Unexpected end of file."
        end

        return chunk_id, chunk_size
      end

      def raise_error(exception_class, message)
        raise exception_class, "Not a supported wave file. #{message}"
      end
    end
  end
end

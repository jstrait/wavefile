module WaveFile
  module ChunkReaders
    # Internal
    class BaseChunkReader    # :nodoc:
      def read_entire_chunk_body(chunk_id)
        begin
          raw_bytes = @io.sysread(@chunk_size)
        rescue EOFError
          raise_error InvalidFormatError, "The #{chunk_id} chunk has incomplete data."
        end

        if raw_bytes.length < @chunk_size
          raise_error InvalidFormatError, "#{chunk_id} indicated size of #{@chunk_size} bytes, but could only read #{raw_bytes.length} bytes."
        end

        raw_bytes
      end

      def raise_error(exception_class, message)
        raise exception_class, "Not a supported wave file. #{message}"
      end
    end
  end
end

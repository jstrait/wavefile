module WaveFile
  module ChunkReaders
    # Internal
    class BaseChunkReader    # :nodoc:
      def read_entire_chunk_body(chunk_id)
        raw_bytes = @io.read(@chunk_size)
        if raw_bytes.nil?
          raw_bytes = ""
        end

        if raw_bytes.length < @chunk_size
          raise_error InvalidFormatError, "'#{chunk_id}' chunk indicated size of #{@chunk_size} bytes, but could only read #{raw_bytes.length} bytes."
        end

        raw_bytes
      end

      def raise_error(exception_class, message)
        raise exception_class, "Not a supported wave file. #{message}"
      end
    end
  end
end

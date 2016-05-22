module WaveFile
  module ChunkReaders
    class BaseChunkReader    # :nodoc:
      def read_chunk_size
        chunk_size = @file.sysread(4).unpack(UNSIGNED_INT_32).first || 0

        # The RIFF specification requires that each chunk be aligned to an even number of bytes,
        # even if the byte count is an odd number.
        #
        # See http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/Docs/riffmci.pdf, page 11.
        if chunk_size.odd?
          chunk_size += 1
        end

        chunk_size
      end

      def raise_error(exception_class, message)
        raise exception_class, "File '#{@file_name}' is not a supported wave file. #{message}"
      end
    end
  end
end

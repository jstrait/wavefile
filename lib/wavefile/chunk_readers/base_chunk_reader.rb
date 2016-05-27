module WaveFile
  module ChunkReaders
    class BaseChunkReader    # :nodoc:
      def raise_error(exception_class, message)
        raise exception_class, "File '#{@file_name}' is not a supported wave file. #{message}"
      end
    end
  end
end

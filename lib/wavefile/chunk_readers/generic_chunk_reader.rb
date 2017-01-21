module WaveFile
  module ChunkReaders
    # Internal
    class GenericChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file, chunk_size)
        @file = file
        @chunk_size = chunk_size
      end

      def read
        @file.sysread(@chunk_size)
      end
    end
  end
end

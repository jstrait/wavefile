module WaveFile
  module ChunkReaders
    class GenericChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file)
        @file = file
      end

      def read
        chunk_size = read_chunk_size
        @file.sysread(chunk_size)
      end
    end
  end
end

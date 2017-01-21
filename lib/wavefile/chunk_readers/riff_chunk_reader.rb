module WaveFile
  module ChunkReaders
    # Internal
    class RiffChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file, chunk_size)
        @file = file
        @chunk_size = chunk_size
      end

      def read
        riff_format = @file.sysread(4)

        unless riff_format == WAVEFILE_FORMAT_CODE
          raise_error InvalidFormatError, "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_format}'"
        end
      end
    end
  end
end

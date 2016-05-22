module WaveFile
  module ChunkReaders
    class RiffChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file)
        @file = file
      end

      def read
        chunk_size = read_chunk_size
        riff_format = @file.sysread(4)

        unless riff_format == WAVEFILE_FORMAT_CODE
          raise_error InvalidFormatError, "Expected RIFF format of '#{WAVEFILE_FORMAT_CODE}', but was '#{riff_format}'"
        end
      end
    end
  end
end

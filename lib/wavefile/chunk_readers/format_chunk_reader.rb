module WaveFile
  module ChunkReaders
    class FormatChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file)
        @file = file
      end

      def read
        chunk_size = read_chunk_size

        if chunk_size < MINIMUM_CHUNK_SIZE
          raise_error InvalidFormatError, "The format chunk is incomplete."
        end

        raw_bytes = read_chunk_body(CHUNK_IDS[:format], chunk_size)

        format_chunk = {}
        format_chunk[:audio_format],
        format_chunk[:channels],
        format_chunk[:sample_rate],
        format_chunk[:byte_rate],
        format_chunk[:block_align],
        format_chunk[:bits_per_sample] = raw_bytes.slice!(0...MINIMUM_CHUNK_SIZE).unpack("vvVVvv")

        if chunk_size > MINIMUM_CHUNK_SIZE
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

      private

      MINIMUM_CHUNK_SIZE = 16

      def read_chunk_body(chunk_id, chunk_size)
        begin
          return @file.sysread(chunk_size)
        rescue EOFError
          raise_error InvalidFormatError, "The #{chunk_id} chunk has incomplete data."
        end
      end
    end
  end
end

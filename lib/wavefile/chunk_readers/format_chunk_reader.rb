module WaveFile
  module ChunkReaders
    # Internal
    class FormatChunkReader < BaseChunkReader    # :nodoc:
      def initialize(io, chunk_size)
        @io = io
        @chunk_size = chunk_size
      end

      def read
        if @chunk_size < MINIMUM_CHUNK_SIZE
          raise_error InvalidFormatError, "The format chunk is incomplete; it contains fewer than the required number of fields."
        end

        raw_bytes = read_entire_chunk_body(CHUNK_IDS[:format])

        format_chunk = {}
        format_chunk[:audio_format],
        format_chunk[:channels],
        format_chunk[:sample_rate],
        format_chunk[:byte_rate],
        format_chunk[:block_align],
        format_chunk[:bits_per_sample] = raw_bytes.slice!(0...MINIMUM_CHUNK_SIZE).unpack("vvVVvv")

        if @chunk_size > MINIMUM_CHUNK_SIZE
          format_chunk[:extension_size] = raw_bytes.slice!(0...2).unpack(UNSIGNED_INT_16).first

          if format_chunk[:extension_size] == nil
            raise_error InvalidFormatError, "The format chunk is missing an expected extension."
          end

          if format_chunk[:extension_size] != raw_bytes.length
            raise_error InvalidFormatError, "The format chunk extension is shorter than expected."
          end

          if format_chunk[:audio_format] == FORMAT_CODES[:extensible]
            format_chunk[:valid_bits_per_sample] = raw_bytes.slice!(0...2).unpack(UNSIGNED_INT_16).first
            format_chunk[:speaker_mapping] = raw_bytes.slice!(0...4).unpack(UNSIGNED_INT_32).first
            format_chunk[:sub_audio_format_guid] = raw_bytes
          end
        end

        UnvalidatedFormat.new(format_chunk)
      end

      private

      MINIMUM_CHUNK_SIZE = 16
    end
  end
end

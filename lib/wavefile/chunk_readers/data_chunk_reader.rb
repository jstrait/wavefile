module WaveFile
  module ChunkReaders
    class DataChunkReader < BaseChunkReader    # :nodoc:
      def initialize(file, raw_native_format, format=nil)
        @file = file
        @raw_native_format = raw_native_format

        data_chunk_size = @file.sysread(4).unpack(UNSIGNED_INT_32).first

        @total_sample_frames = data_chunk_size / @raw_native_format.block_align
        @current_sample_frame = 0

        native_sample_format = "#{FORMAT_CODES.invert[@raw_native_format.audio_format]}_#{@raw_native_format.bits_per_sample}".to_sym

        @readable_format = true
        begin
          @native_format = Format.new(@raw_native_format.channels,
                                      native_sample_format,
                                      @raw_native_format.sample_rate)
          @pack_code = PACK_CODES[@native_format.sample_format][@native_format.bits_per_sample]
        rescue FormatError
          @readable_format = false
          @pack_code = nil
        end

        @format = (format == nil) ? (@native_format || @raw_native_format) : format
      end

      def read(sample_frame_count)
        raise UnsupportedFormatError unless @readable_format

        if @current_sample_frame >= @total_sample_frames
          #FIXME: Do something different here, because the end of the file has not actually necessarily been reached
          raise EOFError
        elsif sample_frame_count > sample_frames_remaining
          sample_frame_count = sample_frames_remaining
        end

        samples = @file.sysread(sample_frame_count * @native_format.block_align).unpack(@pack_code)
        @current_sample_frame += sample_frame_count

        if @native_format.bits_per_sample == 24
          # Since the sample data is little endian, the 3 bytes will go from least->most significant
          samples = samples.each_slice(3).map {|least_significant_byte, middle_byte, most_significant_byte|
            # Convert the byte read as "C" to one read as "c"
            most_significant_byte = [most_significant_byte].pack("c").unpack("c").first
            
            (most_significant_byte << 16) | (middle_byte << 8) | least_significant_byte
          }
        end

        if @native_format.channels > 1
          samples = samples.each_slice(@native_format.channels).to_a
        end

        buffer = Buffer.new(samples, @native_format)
        buffer.convert(@format)
      end

      attr_reader :raw_native_format,
                  :format,
                  :current_sample_frame,
                  :total_sample_frames,
                  :readable_format

    private

      # The number of sample frames in the file after the current sample frame
      def sample_frames_remaining
        @total_sample_frames - @current_sample_frame
      end
    end
  end
end

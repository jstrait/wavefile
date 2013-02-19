module WaveFile
  class Info
    def initialize(file_name, raw_format_chunk, sample_frame_count)
      @file_name = file_name
      @audio_format = raw_format_chunk[:audio_format]
      @channels = raw_format_chunk[:channels]
      @bits_per_sample = raw_format_chunk[:bits_per_sample]
      @sample_rate = raw_format_chunk[:sample_rate]
      @byte_rate = raw_format_chunk[:byte_rate]
      @block_align = raw_format_chunk[:block_align]
      @sample_frame_count = sample_frame_count

      @duration = Duration.new(@sample_frame_count, @sample_rate)
    end

    attr_reader :file_name,
                :audio_format, :channels, :bits_per_sample, :sample_rate, :byte_rate, :block_align,
                :sample_frame_count, :duration
  end
end

module WaveFile
  module ChunkReaders
    # Internal
    class SampleChunkReader < BaseChunkReader    # :nodoc:
      def initialize(io, chunk_size)
        @io = io
        @chunk_size = chunk_size
      end

      def read
        raw_bytes = read_entire_chunk_body(CHUNK_IDS[:sample])

        fields = {}
        fields[:manufacturer_id],
        fields[:product_id],
        fields[:sample_duration],
        fields[:midi_note],
        fields[:fine_tuning_cents],
        fields[:smpte_format],
        smpte_offset_frame_count,
        smpte_offset_seconds,
        smpte_offset_minutes,
        smpte_offset_hours,
        loop_count,
        sampler_data_size = raw_bytes.slice!(0...CORE_BYTE_COUNT).unpack("VVVVVVCCCcVV")
        fields[:fine_tuning_cents] = (fields[:fine_tuning_cents] / 4_294_967_296.0) * 100
        fields[:smpte_offset] = {
          hours: smpte_offset_hours,
          minutes: smpte_offset_minutes,
          seconds: smpte_offset_seconds,
          frame_count: smpte_offset_frame_count,
        }.freeze

        fields[:loops] = []
        loop_count.times do
          if raw_bytes.length < LOOP_BYTE_COUNT
            raise_error InvalidFormatError, "`smpl` chunk loop count is #{loop_count}, but it does not contain that many loops"
          end

          loop_fields = {}
          loop_fields[:id],
          loop_fields[:type],
          loop_fields[:start_sample_frame],
          loop_fields[:end_sample_frame],
          loop_fields[:fraction],
          loop_fields[:play_count] = raw_bytes.slice!(0...LOOP_BYTE_COUNT).unpack("VVVVVV")
          loop_fields[:type] = loop_fields[:type]
          loop_fields[:fraction] /= 4_294_967_296.0

          fields[:loops] << SamplerLoop.new(loop_fields)
        end

        if sampler_data_size > 0
          if raw_bytes.length < sampler_data_size
            raise_error InvalidFormatError, "`smpl` chunk \"sampler specific data\" field is smaller than expected."
          end

          fields[:sampler_specific_data] = raw_bytes.slice!(0...sampler_data_size)
        else
          fields[:sampler_specific_data] = nil
        end

        SamplerInfo.new(fields)
      end

      private

      CORE_BYTE_COUNT = 36
      LOOP_BYTE_COUNT = 24
    end
  end
end

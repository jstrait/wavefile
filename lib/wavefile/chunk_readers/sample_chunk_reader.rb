module WaveFile
  module ChunkReaders
    # Internal
    class SampleChunkReader < BaseChunkReader    # :nodoc:
      def initialize(io, chunk_size)
        @io = io
        @chunk_size = chunk_size
      end

      def read
        raw_bytes = @io.sysread(@chunk_size)

        fields = {}
        fields[:manufacturer_id],
        fields[:product_id],
        fields[:sample_duration],
        fields[:midi_note],
        fields[:pitch_fraction],
        fields[:smpte_format],
        fields[:smpte_offset_hours],
        fields[:smpte_offset_minutes],
        fields[:smpte_offset_seconds],
        fields[:smpte_offset_frame_count],
        fields[:loop_count],
        fields[:sampler_data_size] = raw_bytes.slice!(0...CORE_BYTE_COUNT).unpack("VVVVVVcCCCVV")

        fields[:loops] = []
        fields[:loop_count].times do
          loop_fields = {}
          loop_fields[:id],
          loop_fields[:type],
          loop_fields[:start_sample_frame],
          loop_fields[:end_sample_frame],
          loop_fields[:fraction],
          loop_fields[:play_count] = raw_bytes.slice!(0...LOOP_BYTE_COUNT).unpack("VVVVVV")

          fields[:loops] << Loop.new(loop_fields)
        end

        fields[:sampler_specific_data] = raw_bytes.slice!(0...fields[:sampler_data_size])

        SampleChunk.new(fields)
      end

      class SampleChunk
        def initialize(fields)
          @manufacturer_id = fields[:manufacturer_id]
          @product_id = fields[:product_id]
          @sample_duration = fields[:sample_duration]
          @midi_note = fields[:midi_note]
          @fine_tuning_cents = (fields[:pitch_fraction] / 4_294_967_296.0) * 100
          @smpte_format = fields[:smpte_format]
          @smpte_offset = {
            hours: fields[:smpte_offset_hours],
            minutes: fields[:smpte_offset_minutes],
            seconds: fields[:smpte_offset_seconds],
            frame_count: fields[:smpte_offset_frame_count],
          }.freeze
          @loops = fields[:loops]
          @sampler_specific_data = fields[:sampler_specific_data]
        end

        # Public: Returns the ID of the manufacturer that this sample is intended for. If it's not
        #         intended for a sampler from a particular manufacturer, this should be 0.
        #         See the list at https://www.midi.org/specifications-old/item/manufacturer-id-numbers
        attr_reader :manufacturer_id

        # Public: Returns the ID of the product made by the manufacturer this sample is intended for.
        #         If not intended for a particular product, this should be 0.
        attr_reader :product_id

        # Public: Returns the length of each sample in nanoseconds, which is typically `1 / sample rate`.
        #         For example, with a sample rate of 44100 this would be 22675 nanoseconds. However, this
        #         can be set to an arbitrary value to allow for fine tuning.
        attr_reader :sample_duration

        # Public: Returns the MIDI note number of the sample (0-127)
        attr_reader :midi_note

        # Public: Returns the number of cents up from the specified MIDI unity note field. 100 cents is equal to
        #         one semitone. For example, if this value is 50, and `midi_note` is 60, then the sample is tuned
        #         half-way between MIDI note 60 and 61. If the value is 0, then the sample has no fine tuning.
        attr_reader :fine_tuning_cents

        # Public: Returns the SMPTE format (0, 24, 25, 29 or 30)
        attr_reader :smpte_format

        # Public: Returns a Hash representing the SMPTE time offset.
        attr_reader :smpte_offset

        # Public: Returns an Array of 0 or more loop specifications.
        attr_reader :loops

        # Public: Returns a String of data specific to the intended target sampler. This is returned as a raw
        #         sequencer of bytes, because the structure of this data depends on the specific sampler. If
        #         you want to use it, you'll have to parse it yourself. If there is no sampler specific data,
        #         this will be an empty string.
        attr_reader :sampler_specific_data
      end

      class Loop
        def initialize(id:, type:, start_sample_frame:, end_sample_frame:, fraction:, play_count:)
          @id = id
          @type = loop_type(type)
          @start_sample_frame = start_sample_frame
          @end_sample_frame = end_sample_frame
          @fraction = fraction / 4_294_967_296.0
          @play_count = play_count
        end

        # Public: Returns the ID of the specific Loop
        attr_reader :id

        # Public: Returns a symbol indicating which direction the loop should run. The possible values
        #         are :forward, :alternating, :backward, or :unknown.
        attr_reader :type

        # Public: Returns the start-position (in sample frames) of the loop
        attr_reader :start_sample_frame

        # Public: Returns the end-position (in sample frames) of the loop. The ending sample frame
        #         should be included in the loop.
        attr_reader :end_sample_frame

        # Public: A value between 0.0 and 1.0 which specifies a fraction of a sample at which to loop.
        #         This allows a loop to be fine tuned at a resolution finer than one sample.
        attr_reader :fraction

        # Public: Returns the number of times to loop. 0 means infinitely.
        attr_reader :play_count

        private

        def loop_type(loop_type_id)
          case loop_type_id
          when 0
            :forward
          when 1
            :alternating
          when 2
            :backward
          else
            :unknown
          end
        end
      end

      private

      CORE_BYTE_COUNT = 36
      LOOP_BYTE_COUNT = 24
    end
  end
end

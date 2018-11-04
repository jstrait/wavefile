module WaveFile
  module ChunkReaders
    # Internal
    class SampleChunkReader < BaseChunkReader    # :nodoc:
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

        # Public: Returns the ID of the manufacturer
        # See the list at https://www.midi.org/specifications-old/item/manufacturer-id-numbers
        attr_reader :manufacturer_id

        # Public: Returns the ID of the product
        attr_reader :product_id

        # Public: Returns the length of each sample in nanoseconds
        attr_reader :sample_duration

        # Public: Returns the MIDI note number of the sample (0-127)
        attr_reader :midi_note

        # Public: Returns the fraction of a semitone up from the specified MIDI unity note field.
        # A value of 0x80000000 means 1/2 semitone (50 cents) and a value of 0x00000000 means no fine tuning between semitones.
        # - https://sites.google.com/site/musicgapi/technical-documents/wav-file-format
        # Integer
        attr_reader :fine_tuning_cents

        # Public: Returns the SMPTE format (0, 24, 25, 29 or 30)
        attr_reader :smpte_format

        # Public: Returns the SMPTE time offset.
        # This value uses a format of 0xhhmmssff where hh is a signed value that specifies the number of hours (-23 to 23),
        # mm is an unsigned value that specifies the number of minutes (0 to 59), ss is an unsigned value that specifies
        # the number of seconds (0 to 59) and ff is an unsigned value that specifies the number of frames (0 to -1).
        # - https://sites.google.com/site/musicgapi/technical-documents/wav-file-format
        attr_reader :smpte_offset

        # Public: Returns the loop specifications
        # Array of Loop objects
        attr_reader :loops

        attr_reader :sampler_specific_data
      end

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
        fields[:sampler_data_size] = raw_bytes.slice!(0...36).unpack("VVVVVVcCCCVV")

        fields[:loops] = []
        fields[:loop_count].times do
          loop_fields = {}
          loop_fields[:id],
          loop_fields[:type],
          loop_fields[:start_sample_frame],
          loop_fields[:end_sample_frame],
          loop_fields[:fraction],
          loop_fields[:play_count] = raw_bytes.slice!(0...24).unpack("VVVVVV")

          fields[:loops] << Loop.new(loop_fields)
        end

        fields[:sampler_specific_data] = raw_bytes.slice!(0...fields[:sampler_data_size])

        SampleChunk.new(fields)
      end

      class Loop
        # Public: Returns the ID of the specific Loop
        attr_reader :id

        # Public: Returns the loop type
        # String
        attr_reader :type

        # Public: Returns the start-position (in samples) of the loop
        attr_reader :start_sample_frame

        # Public: Returns the end-position (in samples) of the loop
        attr_reader :end_sample_frame

        # Public: The fractional value specifies a fraction of a sample at which to loop. This allows a loop to be fine
        # tuned at a resolution greater than one sample. The value can range from 0x00000000 to 0xFFFFFFFF. A value of
        # 0 means no fraction, a value of 0x80000000 means 1/2 of a sample length. 0xFFFFFFFF is the smallest fraction
        # of a sample that can be represented.
        # - https://sites.google.com/site/musicgapi/technical-documents/wav-file-format
        # Integer
        attr_reader :fraction

        # Public: Returns the number of times to loop. 0 means infinitely.
        attr_reader :play_count

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

        def initialize(fields)
          @id = fields[:id]
          @type = loop_type(fields[:type])
          @start_sample_frame = fields[:start_sample_frame]
          @end_sample_frame = fields[:end_sample_frame]
          @fraction = fields[:fraction] / 4_294_967_296.0
          @play_count = fields[:play_count]
        end
      end
    end
  end
end

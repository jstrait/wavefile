module WaveFile
  module ChunkReaders
    # Internal
    class SmplChunkReader < BaseChunkReader    # :nodoc:
      class SmplChunk
        def initialize(fields)
          @manufacturer_id = fields[:manufacturer_id]
          @product_id = fields[:product_id]
          @sample_duration = fields[:sample_duration]
          @midi_note = fields[:midi_note]
          @fine_tuning_cents = (fields[:pitch_fraction] / 4_294_967_296.0) * 100
          @smpte_format = fields[:smpte_format]
          @smpte_offset = fields[:smpte_offset]
          @loop_count = fields[:loop_count]
          @sampler_data_size = fields[:sampler_data_size]
          @loops = fields[:loops]
          @sampler_data = fields[:sampler_data]
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

        # Public: Returns the number of loops defined in the sample
        attr_reader :loop_count

        # Public: Returns a number of bytes used for additional sampler data
        attr_reader :sampler_data_size

        # Public: Returns the loop specifications
        # Array of Loop objects
        attr_reader :loops

        attr_reader :sampler_data
      end

      def initialize(io, chunk_size)
        @io = io
        @chunk_size = chunk_size
      end

      def read
        fields = {}
        fields[:manufacturer_id] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:product_id] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:sample_duration] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:midi_note] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:pitch_fraction] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:smpte_format] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        # TODO: It might make more sense to return the offset in a different format according to specs.
        fields[:smpte_offset] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:loop_count] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:sampler_data_size] = @io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        fields[:loops] = []
        fields[:loop_count].times do
          fields[:loops] << Loop.new(@io)
        end
        fields[:sampler_data] = @io.sysread(fields[:sampler_data_size])

        SmplChunk.new(fields)
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

        def initialize(io)
          @id = io.sysread(4).unpack(UNSIGNED_INT_32)[0]
          loop_type_id = io.sysread(4).unpack(UNSIGNED_INT_32)[0]
          @type = loop_type(loop_type_id)
          @start_sample_frame = io.sysread(4).unpack(UNSIGNED_INT_32)[0]
          @end_sample_frame = io.sysread(4).unpack(UNSIGNED_INT_32)[0]
          @fraction = io.sysread(4).unpack(UNSIGNED_INT_32)[0] / 4_294_967_296.0
          @play_count = io.sysread(4).unpack(UNSIGNED_INT_32)[0]
        end
      end
    end
  end
end

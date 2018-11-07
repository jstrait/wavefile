module WaveFile
  # Public: Provides a way to indicate the data contained in a "smpl" chunk.
  #         That is, information about how the *.wav file could be used by a
  #         sampler, such as the file's MIDI note or loop points. If a *.wav
  #         file contains a "smpl" chunk, then Reader.sample_info will
  #         return an instance of this object with the relevant info.
  #
  # Returns a SamplerInfo containing the info in a file's "smpl" chunk.
  class SamplerInfo
    def initialize(fields)
      @manufacturer_id = fields[:manufacturer_id]
      @product_id = fields[:product_id]
      @sample_duration = fields[:sample_duration]
      @midi_note = fields[:midi_note]
      @fine_tuning_cents = fields[:pitch_fraction]
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

    # Public: Returns the length of each sample in nanoseconds, which is typically <code>1 / sample rate</code>.
    #         For example, with a sample rate of 44100 this would be 22675 nanoseconds. However, this
    #         can be set to an arbitrary value to allow for fine tuning.
    attr_reader :sample_duration

    # Public: Returns the MIDI note number of the sample (0-127)
    attr_reader :midi_note

    # Public: Returns the number of cents up from the specified MIDI unity note field. 100 cents is equal to
    #         one semitone. For example, if this value is 50, and #midi_note is 60, then the sample is tuned
    #         half-way between MIDI note 60 and 61. If the value is 0, then the sample has no fine tuning.
    attr_reader :fine_tuning_cents

    # Public: Returns the SMPTE format (0, 24, 25, 29 or 30)
    attr_reader :smpte_format

    # Public: Returns a Hash representing the SMPTE time offset.
    attr_reader :smpte_offset

    # Public: Returns an Array of 0 or more SamplerLoop objects containing loop point info. Loop point info
    #         can indicate that (for example) the sampler should loop between a given sample range as long
    #         as the sample is played.
    attr_reader :loops

    # Public: Returns a String of data specific to the intended target sampler, or nil if there is no sampler
    #         specific data. This is returned as a raw String because the structure of this data depends on
    #         the specific sampler. If you want to use it, you'll need to unpack the string yourself.
    attr_reader :sampler_specific_data
  end
end

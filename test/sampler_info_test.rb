require "minitest/autorun"
require "wavefile"

include WaveFile

class SamplerInfoTest < Minitest::Test
  VALID_32_BIT_INTEGER_TEST_VALUES = [0, 10, 4_294_967_295]
  INVALID_32_BIT_INTEGER_TEST_VALUES = ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, [10], nil]

  def test_missing_keywords
    assert_raises(ArgumentError) { SamplerInfo.new }
  end

  def test_valid_manufacturer_id
    VALID_32_BIT_INTEGER_TEST_VALUES.each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: valid_value,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.manufacturer_id)
    end
  end

  def test_invalid_manufacturer_id
    INVALID_32_BIT_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: invalid_value,
                        product_id: 0,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_product_id
    VALID_32_BIT_INTEGER_TEST_VALUES.each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: valid_value,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.product_id)
    end
  end

  def test_invalid_product_id
    INVALID_32_BIT_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: invalid_value,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_sample_nanoseconds
    VALID_32_BIT_INTEGER_TEST_VALUES.each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: valid_value,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.sample_nanoseconds)
    end
  end

  def test_invalid_sample_nanoseconds
    INVALID_32_BIT_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: invalid_value,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_midi_note
    VALID_32_BIT_INTEGER_TEST_VALUES.each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: valid_value,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.midi_note)
    end
  end

  def test_invalid_midi_note
    INVALID_32_BIT_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 0,
                        midi_note: invalid_value,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_fine_tuning_cents
    [0, 0.0, 0.5, 50, 50.0, 50.5, 99.99999999999999, 0.0000000000000001].each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 0,
                                     midi_note: 60,
                                     fine_tuning_cents: valid_value,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.fine_tuning_cents)
    end
  end

  def test_invalid_fine_tuning_cents
    ["dsfsfsdf", :foo, -1, 4_294_967_296, nil, [50], 100, 100.0, 100.00000000001, -0.0000000000001].each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 0,
                        midi_note: 60,
                        fine_tuning_cents: invalid_value,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_smpte_format
    VALID_32_BIT_INTEGER_TEST_VALUES.each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: valid_value,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.smpte_format)
    end
  end

  def test_invalid_smpte_format
    INVALID_32_BIT_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: invalid_value,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_smpte_offset
    smpte_timecode = SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0)

    [smpte_timecode].each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: smpte_timecode,
                                     loops: [],
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.smpte_offset)
    end
  end

  def test_invalid_smpte_offset
    smpte_timecode = SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0)

    [1, 1.5, false, ["string"], { key: :value}, [smpte_timecode = SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0), "string"]].each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: invalid_value,
                        loops: [],
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_loops
    loop1 = SamplerLoop.new(id: 0, type: :forward, start_sample_frame: 0, end_sample_frame: 0, fraction: 0.0, play_count: 1)
    loop2 = SamplerLoop.new(id: 0, type: :forward, start_sample_frame: 0, end_sample_frame: 0, fraction: 0.0, play_count: 1)

    [[], [loop1], [loop1, loop2]].each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: valid_value,
                                     sampler_specific_data: "")

      assert_equal(valid_value, sampler_info.loops)
    end
  end

  def test_invalid_loops
    loop1 = SamplerLoop.new(id: 0, type: :forward, start_sample_frame: 0, end_sample_frame: 0, fraction: 0.0, play_count: 1)

    [1, 1.5, false, ["string"], { key: :value}, [loop1, "string"]].each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: invalid_value,
                        sampler_specific_data: "")
      end
    end
  end

  def test_valid_sampler_specific_data
    ["", "1234"].each do |valid_value|
      sampler_info = SamplerInfo.new(manufacturer_id: 0,
                                     product_id: 0,
                                     sample_nanoseconds: 22675,
                                     midi_note: 60,
                                     fine_tuning_cents: 0.0,
                                     smpte_format: 0,
                                     smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                                     loops: [],
                                     sampler_specific_data: valid_value)

      if valid_value.nil?
        assert_nil(sampler_info.sampler_specific_data)
      else
        assert_equal(valid_value, sampler_info.sampler_specific_data)
      end
    end
  end

  def test_invalid_sampler_specific_data
    [1, 1.5, false, ["string"], { key: :value}].each do |invalid_value|
      assert_raises(InvalidSamplerInfoError) do
        SamplerInfo.new(manufacturer_id: 0,
                        product_id: 0,
                        sample_nanoseconds: 22675,
                        midi_note: 60,
                        fine_tuning_cents: 0.0,
                        smpte_format: 0,
                        smpte_offset: SMPTETimecode.new(hours: 0, minutes: 0, seconds: 0, frames: 0),
                        loops: [],
                        sampler_specific_data: invalid_value)
      end
    end
  end
end

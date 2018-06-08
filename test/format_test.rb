require 'minitest/autorun'
require 'wavefile.rb'

include WaveFile

class FormatTest < Minitest::Test
  def test_valid_channels
    [1, 2, 3, 4, 65535].each do |valid_channels|
      assert_equal(valid_channels, Format.new(valid_channels, :pcm_16, 44100).channels)
    end

    assert_equal(1, Format.new(:mono, :pcm_16, 44100).channels)
    assert_equal(2, Format.new(:stereo, :pcm_16, 44100).channels)
  end

  def test_invalid_channels
    ["dsfsfsdf", :foo, 0, -1, 65536, 2.5, 2.0].each do |invalid_channels|
      assert_raises(InvalidFormatError) { Format.new(invalid_channels, :pcm_16, 44100) }
    end
  end

  def test_valid_sample_format
    assert_equal(:pcm, Format.new(:mono, :pcm_8, 44100).sample_format)
    assert_equal(:pcm, Format.new(:mono, :pcm_16, 44100).sample_format)
    assert_equal(:pcm, Format.new(:mono, :pcm_24, 44100).sample_format)
    assert_equal(:pcm, Format.new(:mono, :pcm_32, 44100).sample_format)
    assert_equal(:float, Format.new(:mono, :float, 44100).sample_format)
    assert_equal(:float, Format.new(:mono, :float_32, 44100).sample_format)
    assert_equal(:float, Format.new(:mono, :float_64, 44100).sample_format)
  end

  def test_invalid_sample_format
    ["dsfsfsdf", :foo, :pcm, 0, 12, :pcm_14, :pcm_abc, :float_40].each do |invalid_sample_format|
      assert_raises(InvalidFormatError) { Format.new(:mono, invalid_sample_format, 44100) }
    end
  end

  def test_valid_bits_per_sample
    assert_equal(8, Format.new(:mono, :pcm_8, 44100).bits_per_sample)
    assert_equal(16, Format.new(:mono, :pcm_16, 44100).bits_per_sample)
    assert_equal(24, Format.new(:mono, :pcm_24, 44100).bits_per_sample)
    assert_equal(32, Format.new(:mono, :pcm_32, 44100).bits_per_sample)
    assert_equal(32, Format.new(:mono, :float, 44100).bits_per_sample)
    assert_equal(32, Format.new(:mono, :float_32, 44100).bits_per_sample)
    assert_equal(64, Format.new(:mono, :float_64, 44100).bits_per_sample)
  end

  def test_valid_sample_rate
    [1, 44100, 4294967296].each do |valid_sample_rate|
      assert_equal(valid_sample_rate, Format.new(:mono, :pcm_16, valid_sample_rate).sample_rate)
    end
  end

  def test_invalid_sample_rate
    ["dsfsfsdf", :foo, 0, -1, 4294967297, 44100.5, 44100.0].each do |invalid_sample_rate|
      assert_raises(InvalidFormatError) { Format.new(:mono, :pcm_16, invalid_sample_rate) }
    end
  end

  def test_no_speaker_mapping_set_in_constructor_mono
    assert_equal([:front_center], Format.new(:mono, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor__stereo
    assert_equal([:front_left, :front_right], Format.new(:stereo, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_3_channel
    assert_equal([:front_left, :front_right, :front_center], Format.new(3, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_4_channel
    assert_equal([:front_left, :front_right, :back_left, :back_right], Format.new(4, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_5_channel
    expected_speaker_mapping = [:front_left, :front_right, :front_center, :back_left, :back_right]

    assert_equal(expected_speaker_mapping, Format.new(5, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_6_channel
    expected_speaker_mapping = [:front_left,
                                :front_right,
                                :front_center,
                                :low_frequency,
                                :back_left,
                                :back_right]

    assert_equal(expected_speaker_mapping, Format.new(6, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_7_channel
    expected_speaker_mapping = [:front_left,
                                :front_right,
                                :front_center,
                                :low_frequency,
                                :back_center,
                                :side_left,
                                :side_right]

    assert_equal(expected_speaker_mapping, Format.new(7, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_8_channel
    expected_speaker_mapping = [:front_left,
                                :front_right,
                                :front_center,
                                :low_frequency,
                                :back_left,
                                :back_right,
                                :front_left_of_center,
                                :front_right_of_center]

    assert_equal(expected_speaker_mapping, Format.new(8, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_9_channel
    expected_speaker_mapping = [:front_left,
                                :front_right,
                                :front_center,
                                :low_frequency,
                                :back_left,
                                :back_right,
                                :front_left_of_center,
                                :front_right_of_center,
                                :back_center]

    assert_equal(expected_speaker_mapping, Format.new(9, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_18_channel
    expected_speaker_mapping = [
      :front_left,
      :front_right,
      :front_center,
      :low_frequency,
      :back_left,
      :back_right,
      :front_left_of_center,
      :front_right_of_center,
      :back_center,
      :side_left,
      :side_right,
      :top_center,
      :top_front_left,
      :top_front_center,
      :top_front_right,
      :top_back_left,
      :top_back_center,
      :top_back_right,
    ]

    assert_equal(expected_speaker_mapping, Format.new(18, :pcm_8, 44100).speaker_mapping)
  end

  def test_no_speaker_mapping_set_in_constructor_20_channel
    expected_speaker_mapping = [
      :front_left,
      :front_right,
      :front_center,
      :low_frequency,
      :back_left,
      :back_right,
      :front_left_of_center,
      :front_right_of_center,
      :back_center,
      :side_left,
      :side_right,
      :top_center,
      :top_front_left,
      :top_front_center,
      :top_front_right,
      :top_back_left,
      :top_back_center,
      :top_back_right,
      :undefined,
      :undefined,
    ]

    assert_equal(expected_speaker_mapping, Format.new(20, :pcm_8, 44100).speaker_mapping)
  end

  def test_defined_speaker_mapping_in_constructor
    assert_equal([:front_left, :front_right], Format.new(:stereo, :pcm_8, 44100, speaker_mapping: [:front_left, :front_right]).speaker_mapping)
  end

  def test_defined_speaker_mapping_with_explicitly_undefined_channels_in_constructor
    assert_equal([:front_left, :undefined, :undefined], Format.new(3, :pcm_8, 44100, speaker_mapping: [:front_left, :undefined, :undefined]).speaker_mapping)
  end

  def test_defined_speaker_mapping_with_implicitly_undefined_channels_in_constructor
    assert_equal([:front_left, :undefined, :undefined], Format.new(3, :pcm_8, 44100, speaker_mapping: [:front_left]).speaker_mapping)
  end

  def test_extra_valid_speaker_mapping_fields_in_constructor
    assert_raises(InvalidFormatError) do
      Format.new(2, :pcm_8, 44100, speaker_mapping: [:front_left, :front_right, :front_center, :low_frequency])
    end
  end

  def test_extra_undefined_speaker_mapping_fields_in_constructor
    assert_raises(InvalidFormatError) do
      Format.new(2, :pcm_8, 44100, speaker_mapping: [:front_left, :front_right, :undefined, :undefined])
    end
  end

  def test_extra_invalid_speaker_mapping_fields_in_constructor
    assert_raises(InvalidFormatError) do
      Format.new(2, :pcm_8, 44100, speaker_mapping: [:front_left, :front_right, :gibberish, :what_is_this])
    end
  end

  def test_speaker_mapping_is_frozen_copy
    original_speaker_mapping = [:front_left, :front_right]

    format = Format.new(:stereo, :pcm_16, 44100, speaker_mapping: original_speaker_mapping)

    # Changing the original input array after constructing the `Format` doesn't change the `Format` speaker mapping
    assert_equal([:front_left, :front_right], format.speaker_mapping)
    original_speaker_mapping.push(:front_center)
    assert_equal([:front_left, :front_right], format.speaker_mapping)

    # Changing the underlaying Array should raise an error, since the Array should be frozen
    assert_raises(RuntimeError) { format.speaker_mapping.push(:front_center) }
  end

  def test_invalid_speaker_mapping
    mapping_with_invalid_speaker = [:front_left, :bad_speaker]
    mapping_with_duplicate_speaker = [:front_left, :front_right, :front_left]
    mapping_with_out_of_order_speakers = [:front_center, :front_left, :front_right]
    mapping_with_out_of_order_speakers_2 = [:undefined, :front_left, :front_right]
    mapping_with_out_of_order_speakers_3 = [:front_left, :undefined, :front_right]

    assert_raises(InvalidFormatError) { Format.new(:stereo, :pcm_16, 44100, speaker_mapping: mapping_with_invalid_speaker) }
    assert_raises(InvalidFormatError) { Format.new(3, :pcm_16, 44100, speaker_mapping: mapping_with_duplicate_speaker) }
    assert_raises(InvalidFormatError) { Format.new(3, :pcm_16, 44100, speaker_mapping: mapping_with_out_of_order_speakers) }
    assert_raises(InvalidFormatError) { Format.new(3, :pcm_16, 44100, speaker_mapping: mapping_with_out_of_order_speakers_2) }
    assert_raises(InvalidFormatError) { Format.new(3, :pcm_16, 44100, speaker_mapping: mapping_with_out_of_order_speakers_3) }

    ["dsfsfsdf", :foo, 5].each do |invalid_speaker_mapping|
      assert_raises(InvalidFormatError) { Format.new(:mono, :pcm_16, 44100, speaker_mapping: invalid_speaker_mapping) }
    end
  end

  def test_byte_and_block_align
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, :pcm_8, 44100)
      assert_equal(44100, format.byte_rate)
      assert_equal(1, format.block_align)

      format = Format.new(one_channel, :pcm_16, 44100)
      assert_equal(88200, format.byte_rate)
      assert_equal(2, format.block_align)

      format = Format.new(one_channel, :pcm_24, 44100)
      assert_equal(132300, format.byte_rate)
      assert_equal(3, format.block_align)

      [:pcm_32, :float, :float_32].each do |format_code|
        format = Format.new(one_channel, format_code, 44100)
        assert_equal(176400, format.byte_rate)
        assert_equal(4, format.block_align)
      end

      format = Format.new(one_channel, :float_64, 44100)
      assert_equal(352800, format.byte_rate)
      assert_equal(8, format.block_align)
    end

    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, :pcm_8, 44100)
      assert_equal(88200, format.byte_rate)
      assert_equal(2, format.block_align)

      format = Format.new(two_channels, :pcm_16, 44100)
      assert_equal(176400, format.byte_rate)
      assert_equal(4, format.block_align)

      format = Format.new(two_channels, :pcm_24, 44100)
      assert_equal(264600, format.byte_rate)
      assert_equal(6, format.block_align)

      [:pcm_32, :float, :float_32].each do |format_code|
        format = Format.new(two_channels, format_code, 44100)
        assert_equal(352800, format.byte_rate)
        assert_equal(8, format.block_align)
      end

      format = Format.new(two_channels, :float_64, 44100)
      assert_equal(705600, format.byte_rate)
      assert_equal(16, format.block_align)
    end
  end

  def test_mono?
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, :pcm_8, 44100)
      assert_equal(true, format.mono?)
      assert_equal(false, format.stereo?)
    end
  end

  def test_stereo?
    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, :pcm_8, 44100)
      assert_equal(false, format.mono?)
      assert_equal(true, format.stereo?)
    end
  end
end

require "minitest/autorun"
require "wavefile"

include WaveFile

class UnvalidatedFormatTest < Minitest::Test
  def test_initialize
    format = UnvalidatedFormat.new({:audio_format => 65534,
                                    :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                    :channels => 2,
                                    :sample_rate => 44100,
                                    :byte_rate => 176400,
                                    :block_align => 4,
                                    :bits_per_sample => 16,
                                    :valid_bits_per_sample => 14,
                                    :speaker_mapping => 3})  # Bit field '11'

    assert_equal(65534,  format.audio_format)
    assert_equal(SUB_FORMAT_GUID_PCM, format.sub_audio_format_guid)
    assert_equal(2,      format.channels)
    assert_equal(false,  format.mono?)
    assert_equal(true,   format.stereo?)
    assert_equal(44100,  format.sample_rate)
    assert_equal(176400, format.byte_rate)
    assert_equal(4,      format.block_align)
    assert_equal(16,     format.bits_per_sample)
    assert_equal(14,     format.valid_bits_per_sample)
    assert_equal([:front_left, :front_right], format.speaker_mapping)
  end

  def test_to_validated_format_pcm
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 1,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 16})

    validated_format = unvalidated_format.to_validated_format
    assert_equal(:pcm, validated_format.sample_format)
    assert_equal(2, validated_format.channels)
    assert_equal(16, validated_format.bits_per_sample)
    assert_equal(44100, validated_format.sample_rate)
    assert_equal(176400, validated_format.byte_rate)
    assert_equal(4, validated_format.block_align)
    assert_equal([:front_left, :front_right], validated_format.speaker_mapping)
  end

  def test_to_validated_format_float
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 3,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 352800,
                                                :block_align => 8,
                                                :bits_per_sample => 32})

    validated_format = unvalidated_format.to_validated_format
    assert_equal(:float, validated_format.sample_format)
    assert_equal(2, validated_format.channels)
    assert_equal(32, validated_format.bits_per_sample)
    assert_equal(44100, validated_format.sample_rate)
    assert_equal(352800, validated_format.byte_rate)
    assert_equal(8, validated_format.block_align)
    assert_equal([:front_left, :front_right], validated_format.speaker_mapping)
  end

  def test_to_validated_format_unsupported
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 2,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 16})

    assert_raises(InvalidFormatError) { unvalidated_format.to_validated_format }
  end

  def test_to_validated_format_wave_format_extensible_pcm
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 65534,
                                                :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 16,
                                                :valid_bits_per_sample => 16,
                                                :speaker_mapping => 3})

    validated_format = unvalidated_format.to_validated_format
    assert_equal(:pcm, validated_format.sample_format)
    assert_equal(2, validated_format.channels)
    assert_equal(16, validated_format.bits_per_sample)
    assert_equal(44100, validated_format.sample_rate)
    assert_equal(176400, validated_format.byte_rate)
    assert_equal(4, validated_format.block_align)
    assert_equal([:front_left, :front_right], validated_format.speaker_mapping)
  end

  def test_to_validated_format_wave_format_extensible_float
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 65534,
                                                :sub_audio_format_guid => SUB_FORMAT_GUID_FLOAT,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 352800,
                                                :block_align => 8,
                                                :bits_per_sample => 32,
                                                :valid_bits_per_sample => 32,
                                                :speaker_mapping => 5})

    validated_format = unvalidated_format.to_validated_format
    assert_equal(:float, validated_format.sample_format)
    assert_equal(2, validated_format.channels)
    assert_equal(32, validated_format.bits_per_sample)
    assert_equal(44100, validated_format.sample_rate)
    assert_equal(352800, validated_format.byte_rate)
    assert_equal(8, validated_format.block_align)
    assert_equal([:front_left, :front_center], validated_format.speaker_mapping)
  end

  def test_to_validated_format_wave_format_extensible_unsupported_sub_format
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 65534,
                                                :sub_audio_format_guid => "\x02\x00\x00\x00\x00\x00\x10\x00\x80\x00\x00\xAA\x00\x38\x9B\x71",  # ADPCM
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 16,
                                                :valid_bits_per_sample => 16,
                                                :speaker_mapping => 3})

    assert_raises(InvalidFormatError) { unvalidated_format.to_validated_format }
  end

  def test_to_validated_format_wave_format_extensible_unsupported_valid_bits_per_sample
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 65534,
                                                :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 14,
                                                :valid_bits_per_sample => 14,
                                                :speaker_mapping => 3})

    assert_raises(InvalidFormatError) { unvalidated_format.to_validated_format }
  end

  def test_to_validated_format_wave_format_extensible_valid_bits_per_sample_differs_from_container_size
    unvalidated_format = UnvalidatedFormat.new({:audio_format => 65534,
                                                :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                                :channels => 2,
                                                :sample_rate => 44100,
                                                :byte_rate => 176400,
                                                :block_align => 4,
                                                :bits_per_sample => 16,
                                                :valid_bits_per_sample => 14,
                                                :speaker_mapping => 3})

    assert_raises(UnsupportedFormatError) { unvalidated_format.to_validated_format }
  end

  def test_speaker_mapping_no_speakers_defined
    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 3,
                                              :sample_rate => 44100,
                                              :byte_rate => 264600,
                                              :block_align => 6,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 0 })  # According to spec, 0 means speakers
                                                                        # are explicitly undefined for all channels

    assert_equal(3, unvalided_format.channels)
    assert_equal([:undefined, :undefined, :undefined], unvalided_format.speaker_mapping)
  end

  def test_speaker_mapping_more_speakers_defined_than_channels
    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 3,
                                              :sample_rate => 44100,
                                              :byte_rate => 264600,
                                              :block_align => 6,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 214 })  # Bit field '11010110'

    assert_equal(3, unvalided_format.channels)

    # All 5 channel->speaker mappings are present, even though files only has 3 channels
    assert_equal([:front_right, :front_center, :back_left, :front_left_of_center, :front_right_of_center], unvalided_format.speaker_mapping)
  end

  def test_speaker_mapping_more_speakers_than_are_defined
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

    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 3,
                                              :sample_rate => 44100,
                                              :byte_rate => 264600,
                                              :block_align => 6,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 1048575 })  # Bit field '1111_1111_1111_1111_1111'

    assert_equal(3, unvalided_format.channels)

    # All channel->speaker mappings are present, even though file doesn't have this many channels
    assert_equal(expected_speaker_mapping, unvalided_format.speaker_mapping)
  end

  def test_speaker_mapping_more_channels_than_mapped_speakers
    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 3,
                                              :sample_rate => 44100,
                                              :byte_rate => 264600,
                                              :block_align => 6,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 2 })  # Bit field '10'

    assert_equal(3, unvalided_format.channels)
    assert_equal([:front_right, :undefined, :undefined], unvalided_format.speaker_mapping)
  end

  def test_speaker_mapping_more_channels_than_defined_speakers
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
      :undefined,   # Spec only defines first 18 speakers, any subsequent ones are undefined
      :undefined,   # Spec only defines first 18 speakers, any subsequent ones are undefined
    ]

    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 20,
                                              :sample_rate => 44100,
                                              :byte_rate => 1764000,
                                              :block_align => 40,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 262143 })  # Bit field '11_1111_1111_1111_1111'

    assert_equal(20, unvalided_format.channels)
    assert_equal(expected_speaker_mapping, unvalided_format.speaker_mapping)
  end

  def test_speaker_mapping_more_channels_than_defined_speakers_2
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

    unvalided_format = UnvalidatedFormat.new({:audio_format => 65534,
                                              :sub_audio_format_guid => SUB_FORMAT_GUID_PCM,
                                              :channels => 20,
                                              :sample_rate => 44100,
                                              :byte_rate => 264600,
                                              :block_align => 6,
                                              :bits_per_sample => 16,
                                              :valid_bits_per_sample => 16,
                                              :speaker_mapping => 1048575 })  # Bit field '1111_1111_1111_1111_1111'

    assert_equal(20, unvalided_format.channels)

    # All channel->speaker mappings are present, even though file doesn't have this many channels
    assert_equal(expected_speaker_mapping, unvalided_format.speaker_mapping)
  end
end

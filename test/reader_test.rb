require "minitest/autorun"
require "wavefile.rb"
require "wavefile_io_test_helper.rb"

include WaveFile

class ReaderTest < Minitest::Test
  include WaveFileIOTestHelper

  FIXTURE_ROOT_PATH = "test/fixtures/wave"


  def test_nonexistent_file
    assert_raises(Errno::ENOENT) { Reader.new(fixture("i_do_not_exist.wav")) }
  end

  def test_initialize_invalid_formats
    invalid_fixtures = [
      # File contains 0 bytes
      "invalid/empty.wav",

      # File consists of "RIFF" and nothing else
      "invalid/incomplete_riff_header.wav",

      # The RIFF header chunk size field ends prematurely
      "invalid/riff_chunk_has_incomplete_chunk_size.wav",

      # First 4 bytes in the file are not "RIFF"
      "invalid/bad_riff_header.wav",

      # The format code in the RIFF header is missing
      "invalid/no_riff_format.wav",

      # The format code in the RIFF header is truncated; i.e. not a full 4 bytes
      "invalid/incomplete_riff_format.wav",

      # The format code in the RIFF header is not "WAVE"
      "invalid/bad_wavefile_format.wav",

      # The file consists of just a valid RIFF header
      "invalid/riff_chunk_has_no_child_chunks.wav",

      # The format chunk only includes the chunk ID
      "invalid/no_format_chunk_size.wav",

      # The format chunk has 0 bytes in it (despite the chunk size being 16)
      "invalid/empty_format_chunk.wav",

      # The format chunk has some data, but not all of the minimum required.
      "invalid/insufficient_format_chunk.wav",

      # The format chunk has a size of 17, but is missing the required padding byte
      # The extra byte is part of what would be the chunk extension size if the format
      # code weren't 1.
      "invalid/format_chunk_with_extra_byte_and_missing_padding_byte.wav",

      # The format chunk has an odd size with extra bytes at the end, but is
      # missing the required padding byte
      "invalid/format_chunk_extra_bytes_with_odd_size_and_missing_padding_byte.wav",

      # The format chunk is floating point but the extension size field is incomplete
      "invalid/float_format_chunk_extension_size_incomplete.wav",

      # The format chunk is floating point but the extension size field is incomplete.
      # The padding byte which is present should not be interpreted as part of the size field.
      "invalid/float_format_chunk_extension_size_incomplete_with_padding_byte.wav",

      # The format chunk is floating point and has an oversized extension,
      # and the extension is too large to fit in the stated size of the chunk
      "invalid/float_format_chunk_oversized_extension_too_large.wav",

      # The format chunk is extensible, but the required extension is not present
      "invalid/extensible_format_chunk_extension_missing.wav",

      # The format chunk is extensible, but the extension size field is incomplete.
      # The required padding byte is present.
      "invalid/extensible_format_chunk_extension_size_incomplete_with_padding_byte.wav",

      # The format chunk is extensible, but the extension size field is incomplete.
      # The required padding byte is not present.
      "invalid/extensible_format_chunk_extension_size_incomplete.wav",

      # The format chunk is extensible, but the extension is shorter than required
      "invalid/extensible_format_chunk_extension_incomplete.wav",

      # The format chunk is extensible, but the extension is shorter than required
      # (even though the chunk is large enough to contain a full extension).
      "invalid/extensible_format_chunk_extension_incomplete_in_large_enough_chunk.wav",

      # The format chunk is extensible, but the extension is shorter than required
      # (the chunk has a stated size that is large enough, although it is larger than the actual amount of data).
      "invalid/extensible_format_chunk_extension_incomplete_in_incorrectly_sized_chunk.wav",

      # The format chunk is extensible, but the chunk doesn't have enough room for the extension
      "invalid/extensible_format_chunk_extension_truncated.wav",

      # The format chunk is extensible and has an oversized extension,
      # and the extension is too large to fit in the stated size of the chunk
      "invalid/extensible_format_chunk_oversized_extension_too_large.wav",

      # The format chunk has an unsupported format code (not an error),
      # but the extension size field is incomplete.
      "invalid/unsupported_format_extension_size_incomplete.wav",

      # The format chunk has an unsupported format code (not an error),
      # but the extension size field is incomplete.
      # The padding byte which is present should not be interpreted as part of the size field.
      "invalid/unsupported_format_extension_size_incomplete_with_padding_byte.wav",

      # The format chunk has an unsupported format code (not an error),
      # but the chunk doesn't have enough room for the extension.
      "invalid/unsupported_format_extension_truncated.wav",

      # The format chunk has an unsupported format code (not an error),
      # and an oversized extension. The extension is too large to fit in
      # the stated size of the chunk.
      "invalid/unsupported_format_oversized_extension_too_large.wav",

      # The RIFF header and format chunk are OK, but there is no data chunk
      "invalid/no_data_chunk.wav",

      # The data chunk only contains the chunk ID, nothing else
      "invalid/data_chunk_ends_after_chunk_id.wav",

      # The data chunk size field ends prematurely
      "invalid/data_chunk_has_incomplete_chunk_size.wav",

      # The format chunk comes after the data chunk; it must come before
      "invalid/format_chunk_after_data_chunk.wav",

      # Contains a `smpl` chunk that has a size of 0 and no data
      "invalid/smpl_chunk_empty.wav",

      # Contains a `smpl` chunk that doesn't have enough bytes to match the chunk's size
      "invalid/smpl_chunk_truncated.wav",

      # `smpl` chunk does not contain as many loops as the 'loop count' field indicates
      "invalid/smpl_chunk_loop_count_too_high.wav",

      # `smpl` chunk does not contain as bytes as 'sampler specific data size' field indicates
      "invalid/smpl_chunk_truncated_sampler_specific_data.wav",
    ]

    invalid_fixtures.each do |fixture_name|
      file_name = fixture(fixture_name)

      [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
        assert_raises(InvalidFormatError) { Reader.new(io_or_file_name) }
      end
    end
  end

  def test_initialize_unsupported_format
    file_name = fixture("unsupported/unsupported_bits_per_sample.wav")

    # Unsupported format, no read format given
    [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
      reader = Reader.new(io_or_file_name)
      assert_equal(2, reader.native_format.channels)
      assert_equal(20, reader.native_format.bits_per_sample)
      assert_equal(44100, reader.native_format.sample_rate)
      assert_nil(reader.format.speaker_mapping)
      assert_equal(2, reader.format.channels)
      assert_equal(20, reader.format.bits_per_sample)
      assert_equal(44100, reader.format.sample_rate)
      assert_nil(reader.format.speaker_mapping)
      assert_equal(false, reader.closed?)
      assert_equal(0, reader.current_sample_frame)
      assert_equal(0, reader.total_sample_frames)
      assert_equal(false, reader.readable_format?)
      assert_nil(reader.sampler_info)
      reader.close
    end

    # Unsupported format, different read format given
    [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
      reader = Reader.new(io_or_file_name, Format.new(:mono, :pcm_16, 22050))
      assert_equal(2, reader.native_format.channels)
      assert_equal(20, reader.native_format.bits_per_sample)
      assert_equal(44100, reader.native_format.sample_rate)
      assert_nil(reader.native_format.speaker_mapping)
      assert_equal(1, reader.format.channels)
      assert_equal(16, reader.format.bits_per_sample)
      assert_equal(22050, reader.format.sample_rate)
      assert_equal([:front_center], reader.format.speaker_mapping)
      assert_equal(false, reader.closed?)
      assert_equal(0, reader.current_sample_frame)
      assert_equal(0, reader.total_sample_frames)
      assert_equal(false, reader.readable_format?)
      assert_nil(reader.sampler_info)
      reader.close
    end
  end

  def test_read_from_unsupported_format
    unsupported_fixtures = [
      # Format code has an unsupported value
      "unsupported/unsupported_audio_format.wav",

      # Format code has an unsupported value, and the format
      # chunk has an extension.
      "unsupported/unsupported_format_code_with_extension.wav",

      # Format code has an unsupported value, and the format chunk does not
      # have the expected "extension size" field. This field is not required
      # by the gem so this should not cause `InvalidFormatError` to be raised.
      "unsupported/unsupported_format_code_missing_extension_size.wav",

      # Format code has an unsupported value, the format chunk has an extension,
      # and extra bytes follow the extension.
      "unsupported/unsupported_format_code_with_extension_and_extra_bytes.wav",

      # Format code has an unsupported value, and a chunk extension that
      # is smaller than is should be for the given format code. However,
      # this should not cause an error because chunk extensions for unsupported
      # formats are not parsed.
      "unsupported/unsupported_format_code_with_incomplete_extension.wav",

      # Format code has an unsupported value, and the format chunk has an oversized
      # extension with extra bytes at the end.
      "unsupported/unsupported_format_code_with_oversized_extension.wav",

      # Format code has an unsupported value, the format chunk has an oversized extension
      # with extra bytes at the end, and extra bytes follow the extension.
      "unsupported/unsupported_format_code_with_oversized_extension_and_extra_bytes.wav",

      # Bits per sample is 20, which is not supported
      "unsupported/unsupported_bits_per_sample.wav",

      # Channel count is 0
      "unsupported/bad_channel_count.wav",

      # Sample rate is 0
      "unsupported/bad_sample_rate.wav",

      # WAVEFORMATEXTENSIBLE, container size doesn't match sample size
      # Although this is valid, this is not currently supported by this gem
      "unsupported/extensible_container_size_bigger_than_sample_size.wav",

      # WAVEFORMATEXTENSIBLE, the subformat GUID is not a valid format
      # supported by this gem.
      "unsupported/extensible_unsupported_subformat_guid.wav",
    ]

    unsupported_fixtures.each do |fixture_name|
      file_name = fixture(fixture_name)

      [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
        reader = Reader.new(io_or_file_name)
        assert_equal(false, reader.readable_format?)
        assert_raises(UnsupportedFormatError) { reader.read(1024) }
        assert_raises(UnsupportedFormatError) { reader.each_buffer(1024) {|buffer| buffer } }

        reader.close
      end
    end
  end

  def test_initialize
    format = Format.new(:stereo, :pcm_16, 22050)

    exhaustively_test do |format_chunk_format, channels, sample_format|
      file_name = fixture("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav")
      bits_per_sample = sample_format.to_s.split("_").last.to_i

      # Native format
      [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
        reader = Reader.new(io_or_file_name)
        assert_equal(CHANNEL_ALIAS[channels], reader.native_format.channels)
        assert_equal(bits_per_sample, reader.native_format.bits_per_sample)
        assert_equal(44100, reader.native_format.sample_rate)
        assert_equal(CHANNEL_ALIAS[channels], reader.format.channels)
        assert_equal(bits_per_sample, reader.format.bits_per_sample)
        assert_equal(44100, reader.format.sample_rate)
        assert_equal(false, reader.closed?)
        assert_equal(0, reader.current_sample_frame)
        assert_equal(2240, reader.total_sample_frames)
        assert_equal(true, reader.readable_format?)
        assert_nil(reader.sampler_info)
        reader.close
      end

      # Non-native format
      [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
        reader = Reader.new(io_or_file_name, format)
        assert_equal(CHANNEL_ALIAS[channels], reader.native_format.channels)
        assert_equal(bits_per_sample, reader.native_format.bits_per_sample)
        assert_equal(44100, reader.native_format.sample_rate)
        assert_equal(2, reader.format.channels)
        assert_equal(16, reader.format.bits_per_sample)
        assert_equal(22050, reader.format.sample_rate)
        assert_equal(false, reader.closed?)
        assert_equal(0, reader.current_sample_frame)
        assert_equal(2240, reader.total_sample_frames)
        assert_equal(true, reader.readable_format?)
        assert_nil(reader.sampler_info)
        reader.close
      end

      # Block is given.
      [file_name, string_io_from_file(file_name)].each do |io_or_file_name|
        reader = Reader.new(io_or_file_name) {|r| r.read(1024) }
        assert_equal(CHANNEL_ALIAS[channels], reader.native_format.channels)
        assert_equal(bits_per_sample, reader.native_format.bits_per_sample)
        assert_equal(44100, reader.native_format.sample_rate)
        assert_equal(CHANNEL_ALIAS[channels], reader.format.channels)
        assert_equal(bits_per_sample, reader.format.bits_per_sample)
        assert_equal(44100, reader.format.sample_rate)
        assert(reader.closed?)
        assert_equal(1024, reader.current_sample_frame)
        assert_equal(2240, reader.total_sample_frames)
        assert_equal(true, reader.readable_format?)
        assert_nil(reader.sampler_info)
      end
    end
  end

  def test_read_native_format
    exhaustively_test do |format_chunk_format, channels, sample_format|
      buffers = read_file("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav", 1024)

      assert_equal(3, buffers.length)
      assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[0].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[1].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 24,  buffers[2].samples)
    end
  end

  def test_read_native_extensible_format
    channels = :stereo
    sample_format = :pcm_16

    reader = Reader.new(fixture("valid/extensible_stereo_pcm_16_44100.wav"))
    assert_equal(2, reader.native_format.channels)
    assert_equal(16, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(16, reader.native_format.valid_bits_per_sample)
    assert_equal([:front_left, :front_right], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(2, reader.format.channels)
    assert_equal(16, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_left, :front_right], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_stereo_pcm_16_44100.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 24,  buffers[2].samples)
  end

  def test_read_extensible_no_speaker_mapping
    reader = Reader.new(fixture("valid/extensible_stereo_pcm_24_44100_no_speaker_mapping.wav"))

    assert_equal(2, reader.native_format.channels)
    assert_equal(24, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(24, reader.native_format.valid_bits_per_sample)
    assert_equal([:undefined, :undefined], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(2, reader.format.channels)
    assert_equal(24, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:undefined, :undefined], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_stereo_pcm_24_44100_no_speaker_mapping.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_24] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_24] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_24] * 24,  buffers[2].samples)
  end

  def test_read_extensible_more_speakers_than_channels
    reader = Reader.new(fixture("valid/extensible_stereo_pcm_16_44100_more_speakers_than_channels.wav"))

    assert_equal(2, reader.native_format.channels)
    assert_equal(16, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(16, reader.native_format.valid_bits_per_sample)
    assert_equal([:front_left, :front_right, :front_center, :low_frequency], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(2, reader.format.channels)
    assert_equal(16, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_left, :front_right], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_stereo_pcm_16_44100_more_speakers_than_channels.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_extensible_more_speakers_than_defined_by_spec
    reader = Reader.new(fixture("valid/extensible_stereo_pcm_16_44100_more_speakers_than_defined_by_spec.wav"))

    assert_equal(2, reader.native_format.channels)
    assert_equal(16, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(16, reader.native_format.valid_bits_per_sample)
    # Extra bits for speakers beyond the first 18 are set in the file, but these bits should be ignored
    assert_equal([:front_left,
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
                  :top_back_right], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(2, reader.format.channels)
    assert_equal(16, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_left, :front_right], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_stereo_pcm_16_44100_more_speakers_than_defined_by_spec.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_extensible_only_undefined_high_bit_speakers
    reader = Reader.new(fixture("valid/extensible_stereo_pcm_16_44100_only_undefined_high_bit_speakers.wav"))

    assert_equal(2, reader.native_format.channels)
    assert_equal(16, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(16, reader.native_format.valid_bits_per_sample)
    assert_equal([:undefined, :undefined], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(2, reader.format.channels)
    assert_equal(16, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:undefined, :undefined], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_stereo_pcm_16_44100_only_undefined_high_bit_speakers.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_non_extensible_that_has_extension
    reader = Reader.new(fixture("valid/mono_pcm_16_44100_with_extension.wav"))

    assert_equal(1, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(16, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(16, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/mono_pcm_16_44100_with_extension.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_float_format_chunk_missing_extension_size
    reader = Reader.new(fixture("valid/float_format_chunk_missing_extension_size.wav"))

    assert_equal(3, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(32, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(32, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/float_format_chunk_missing_extension_size.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 24,  buffers[2].samples)
  end

  def test_read_format_chunk_with_extra_bytes
    reader = Reader.new(fixture("valid/format_chunk_with_extra_bytes.wav"))

    assert_equal(1, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/format_chunk_with_extra_bytes.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_format_chunk_with_extra_byte_and_padding_byte
    reader = Reader.new(fixture("valid/format_chunk_with_extra_byte_and_padding_byte.wav"))

    assert_equal(1, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/format_chunk_with_extra_byte_and_padding_byte.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_format_chunk_with_extra_bytes_with_odd_size_and_padding_byte
    reader = Reader.new(fixture("valid/format_chunk_extra_bytes_with_odd_size_and_padding_byte.wav"))

    assert_equal(1, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/format_chunk_extra_bytes_with_odd_size_and_padding_byte.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_float_format_chunk_with_oversized_extension
    reader = Reader.new(fixture("valid/float_format_chunk_oversized_extension.wav"))

    assert_equal(3, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(32, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(32, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/float_format_chunk_oversized_extension.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 24,  buffers[2].samples)
  end

  def test_read_float_format_chunk_with_extra_bytes
    reader = Reader.new(fixture("valid/float_format_chunk_with_extra_bytes.wav"))

    assert_equal(3, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(32, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(32, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/float_format_chunk_with_extra_bytes.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 24,  buffers[2].samples)
  end

  def test_read_float_format_chunk_with_oversized_extension_and_extra_bytes
    reader = Reader.new(fixture("valid/float_format_chunk_oversized_extension_and_extra_bytes.wav"))

    assert_equal(3, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(32, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_nil(reader.native_format.speaker_mapping)
    assert_nil(reader.native_format.sub_audio_format_guid)
    assert_nil(reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(32, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/float_format_chunk_with_extra_bytes.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:float] * 24,  buffers[2].samples)
  end

  def test_read_extensible_format_chunk_with_oversized_extension
    reader = Reader.new(fixture("valid/extensible_format_chunk_oversized_extension.wav"))

    assert_equal(65534, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(8, reader.native_format.valid_bits_per_sample)
    assert_equal([:front_center], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_format_chunk_oversized_extension.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_extensible_format_chunk_with_extra_bytes
    reader = Reader.new(fixture("valid/extensible_format_chunk_with_extra_bytes.wav"))

    assert_equal(65534, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(8, reader.native_format.valid_bits_per_sample)
    assert_equal([:front_center], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(8, reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_format_chunk_with_extra_bytes.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_extensible_format_chunk_with_oversized_extension_and_extra_bytes
    reader = Reader.new(fixture("valid/extensible_format_chunk_oversized_extension_and_extra_bytes.wav"))

    assert_equal(65534, reader.native_format.audio_format)
    assert_equal(1, reader.native_format.channels)
    assert_equal(8, reader.native_format.bits_per_sample)
    assert_equal(44100, reader.native_format.sample_rate)
    assert_equal(8, reader.native_format.valid_bits_per_sample)
    assert_equal([:front_center], reader.native_format.speaker_mapping)
    assert_equal(WaveFile::SUB_FORMAT_GUID_PCM, reader.native_format.sub_audio_format_guid)
    assert_equal(8, reader.native_format.valid_bits_per_sample)
    assert_equal(1, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(44100, reader.format.sample_rate)
    assert_equal([:front_center], reader.format.speaker_mapping)
    assert_equal(false, reader.closed?)
    assert_equal(0, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
    assert_equal(true, reader.readable_format?)
    assert_nil(reader.sampler_info)
    reader.close

    buffers = read_file("valid/extensible_format_chunk_with_extra_bytes.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_with_format_conversion
    buffers = read_file("valid/mono_pcm_16_44100.wav", 1024, Format.new(:stereo, :pcm_8, 22100))

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 24,  buffers[2].samples)
  end

  def test_read_with_padding_byte
    buffers = read_file("valid/mono_pcm_8_44100_with_padding_byte.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 193], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal((SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24) + [88],
                 buffers[2].samples)
  end

  def test_read_truncated_file
    reader = Reader.new(fixture("invalid/data_chunk_truncated.wav"), Format.new(:mono, :pcm_8, 44100))

    # The chunk does not actually contain this many sample frames, it actually has 2240
    assert_equal(100000, reader.total_sample_frames)
    assert_equal(0, reader.current_sample_frame)

    # First set of requested sample frames should be read correctly
    buffer = reader.read(2000)
    assert_equal(2000, buffer.samples.length)
    assert_equal(2000, reader.current_sample_frame)

    # All of the remaining sample frames are returned, which is fewer than were requested.
    buffer = reader.read(2000)
    assert_equal(240, buffer.samples.length)
    assert_equal(2240, reader.current_sample_frame)

    # Since there are no more sample frames, an end-of-file error should be raised
    assert_raises(EOFError) { reader.read(2000) }
  end

  def test_each_buffer_no_block_given
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"))
    assert_raises(LocalJumpError) { reader.each_buffer(1024) }
  end

  def test_each_buffer_no_buffer_size_given
    exhaustively_test do |format_chunk_format, channels, sample_format|
      reader = Reader.new(fixture("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav"))

      buffers = []
      reader.each_buffer {|buffer| buffers << buffer }

      assert(reader.closed?)
      assert_equal(1, buffers.length)
      assert_equal([2240], buffers.map {|buffer| buffer.samples.length })
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 280, buffers[0].samples)
      assert_equal(2240, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
    end
  end

  def test_each_buffer_native_format
    exhaustively_test do |format_chunk_format, channels, sample_format|
      reader = Reader.new(fixture("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav"))

      buffers = []
      reader.each_buffer(1024) {|buffer| buffers << buffer }

      assert(reader.closed?)
      assert_equal(3, buffers.length)
      assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[0].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 128, buffers[1].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][sample_format] * 24,  buffers[2].samples)
      assert_equal(2240, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
    end
  end

  def test_each_buffer_with_format_conversion
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"), Format.new(:stereo, :pcm_8, 22050))
    assert_equal(2, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(22050, reader.format.sample_rate)

    buffers = []
    reader.each_buffer(1024) {|buffer| buffers << buffer }

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][:pcm_8] * 24,  buffers[2].samples)
    assert_equal(2240, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
  end

  def test_each_buffer_with_padding_byte
    buffers = []
    reader = Reader.new(fixture("valid/mono_pcm_8_44100_with_padding_byte.wav"))
    reader.each_buffer(1024) {|buffer| buffers << buffer }

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 193], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, buffers[1].samples)
    assert_equal((SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 24) + [88],
                 buffers[2].samples)
    assert_equal(2241, reader.current_sample_frame)
    assert_equal(2241, reader.total_sample_frames)
  end

  def test_each_buffer_not_at_beginning_of_file
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"))

    buffers = []
    reader.read(8)
    reader.each_buffer {|buffer| buffers << buffer }

    assert(reader.closed?)
    assert_equal(1, buffers.length)
    assert_equal([2232], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 279, buffers[0].samples)
    assert_equal(2240, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
  end

  def test_each_buffer_inside_reader_block
    buffers = []

    # This should not raise a ReaderClosedError
    Reader.new(fixture("valid/mono_pcm_16_44100.wav")) do |reader|
      reader.each_buffer(1024) {|buffer| buffers << buffer }
    end

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_after_each_buffer_inside_block_raises_error
    buffers = []

    Reader.new(fixture("valid/mono_pcm_16_44100.wav")) do |reader|
      reader.each_buffer(1024) {|buffer| buffers << buffer }
      assert_raises(ReaderClosedError) { reader.read(100) }
    end

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 24,  buffers[2].samples)
  end

  def test_read_non_data_chunk_with_padding_byte
    # This fixture file contains a JUNK chunk with an odd size, aligned to an even number of
    # bytes via an appended padding byte. If the padding byte is not taken into account, this
    # test will blow up due to the file not being synced up to the data chunk in the right place.
    reader = Reader.new(fixture("valid/mono_pcm_16_44100_junk_chunk_with_padding_byte.wav"))
    buffer = reader.read(1024)
    assert_equal(buffer.samples, SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128)
    assert_equal(1024, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
  end

  def test_read_non_data_chunk_is_final_chunk_without_padding_byte
    # This fixture file contains a JUNK chunk with an odd size, but no padding byte. When a chunk
    # is the final chunk in the file, a missing padding byte won't cause an error as long as the
    # RIFF chunk size field matches the actual number of bytes in the file.
    reader = Reader.new(fixture("valid/mono_pcm_16_44100_junk_chunk_final_chunk_missing_padding_byte.wav"))
    buffer = reader.read(1024)
    assert_equal(buffer.samples, SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128)
    assert_equal(1024, reader.current_sample_frame)
    assert_equal(2240, reader.total_sample_frames)
  end

  def test_closed?
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"))
    assert_equal(false, reader.closed?)
    reader.close
    assert(reader.closed?)
    # Closing an already closed Reader should be a no-op
    reader.close
    assert(reader.closed?)

    # For Reader.each_buffer
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"))
    assert_equal(false, reader.closed?)
    reader.each_buffer(1024) do |buffer|
      # No-op
    end
    assert_equal(true, reader.closed?)

    # Constructed from an File IO instance
    io = File.open(fixture("valid/mono_pcm_16_44100.wav"), "rb")
    reader = Reader.new(io)
    assert_equal(false, reader.closed?)
    reader.close
    assert(reader.closed?)
    assert_equal(false, io.closed?)

    # Constructed from an StringIO instance
    io = string_io_from_file(fixture("valid/mono_pcm_16_44100.wav"))
    reader = Reader.new(io)
    assert_equal(false, reader.closed?)
    reader.close
    assert(reader.closed?)
    assert_equal(false, io.closed?)
  end

  def test_read_after_close
    reader = Reader.new(fixture("valid/mono_pcm_16_44100.wav"))
    reader.read(1024)
    reader.close
    assert_raises(ReaderClosedError) { reader.read(1024) }

    io = File.open(fixture("valid/mono_pcm_16_44100.wav"), "rb")
    reader = Reader.new(io)
    reader.read(1024)
    reader.close
    assert_raises(ReaderClosedError) { reader.read(1024) }
  end

  def test_sample_counts_manual_reads
    exhaustively_test do |format_chunk_format, channels, sample_format|
      reader = Reader.new(fixture("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav"))

      assert_equal(0, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
      test_duration({hours: 0, minutes: 0, seconds: 0, milliseconds: 50, sample_count: 2240},
                    reader.total_duration)


      reader.read(1024)
      assert_equal(1024, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
      test_duration({hours: 0, minutes: 0, seconds: 0, milliseconds: 50, sample_count: 2240},
                    reader.total_duration)


      reader.read(1024)
      assert_equal(2048, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
      test_duration({hours: 0, minutes: 0, seconds: 0, milliseconds: 50, sample_count: 2240},
                    reader.total_duration)


      reader.read(192)
      assert_equal(2240, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
      test_duration({hours: 0, minutes: 0, seconds: 0, milliseconds: 50, sample_count: 2240},
                    reader.total_duration)


      reader.close
      assert_equal(2240, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
      test_duration({hours: 0, minutes: 0, seconds: 0, milliseconds: 50, sample_count: 2240},
                    reader.total_duration)
    end
  end

  def test_sample_counts_each_buffer
    exhaustively_test do |format_chunk_format, channels, sample_format|
      expected_results = [ 1024, 2048, 2240 ]

      file_name = fixture("valid/#{format_chunk_format}#{channels}_#{sample_format}_44100.wav")
      reader = Reader.new(file_name)

      assert_equal(0, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)

      reader.each_buffer(1024) do |buffer|
        expected_result = expected_results.slice!(0)

        assert_equal(expected_result, reader.current_sample_frame)
        assert_equal(2240, reader.total_sample_frames)
      end

      assert_equal(2240, reader.current_sample_frame)
      assert_equal(2240, reader.total_sample_frames)
    end
  end

  def test_smpl_chunk
    file_name = fixture("valid/with_sample_chunk_before_data_chunk.wav")
    sampler_info = Reader.new(file_name).sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(:backward, sampler_info.loops[0].type)
    assert_equal(0, sampler_info.loops[0].start_sample_frame)
    assert_equal(0, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(1, sampler_info.loops[0].play_count)
    assert_equal("", sampler_info.sampler_specific_data)
  end

  # Several field values are out of the expected range, but the file should be successfully
  # read anyway because the sample chunk has the correct structure
  def test_smpl_chunk_field_values_out_of_range
    file_name = fixture("valid/with_sample_chunk_with_fields_out_of_range.wav")
    sampler_info = Reader.new(file_name).sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(10000, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(99999, sampler_info.smpte_format)
    assert_equal(-128, sampler_info.smpte_offset.hours)
    assert_equal(128, sampler_info.smpte_offset.minutes)
    assert_equal(8, sampler_info.smpte_offset.seconds)
    assert_equal(1, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(88888, sampler_info.loops[0].type)
    assert_equal(9999999, sampler_info.loops[0].start_sample_frame)
    assert_equal(9999999, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(1, sampler_info.loops[0].play_count)
    assert_equal("", sampler_info.sampler_specific_data)
  end

  def test_smpl_chunk_after_data_chunk
    file_name = fixture("valid/with_sample_chunk_after_data_chunk.wav")
    sampler_info = Reader.new(file_name).sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(:backward, sampler_info.loops[0].type)
    assert_equal(0, sampler_info.loops[0].start_sample_frame)
    assert_equal(0, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(1, sampler_info.loops[0].play_count)
    assert_equal("", sampler_info.sampler_specific_data)
  end

  def test_smpl_chunk_after_data_chunk_and_data_chunk_has_padding_byte
    file_name = fixture("valid/with_sample_chunk_after_data_chunk_and_data_chunk_has_padding_byte.wav")

    reader = Reader.new(file_name)
    sampler_info = reader.sampler_info

    # Should correctly deal with data chunk with odd number of bytes, followed
    # by a padding byte.
    assert_equal(2241, reader.total_sample_frames)
    # Test that data chunk read is correctly queued up to start of data chunk
    assert_equal([88, 88, 88, 88, 167, 167, 167, 167], reader.read(8).samples)

    # Sample chunk should be correctly located despite the padding byte following
    # the data chunk.
    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(:backward, sampler_info.loops[0].type)
    assert_equal(0, sampler_info.loops[0].start_sample_frame)
    assert_equal(0, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(1, sampler_info.loops[0].play_count)
    assert_equal("", sampler_info.sampler_specific_data)
  end

  def test_smpl_chunk_with_sampler_specific_data
    file_name = fixture("valid/with_sample_chunk_with_sampler_specific_data.wav")
    sampler_info = Reader.new(file_name).sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(:backward, sampler_info.loops[0].type)
    assert_equal(0, sampler_info.loops[0].start_sample_frame)
    assert_equal(0, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(Float::INFINITY, sampler_info.loops[0].play_count)
    assert_equal("\x04\x01\x03\x02", sampler_info.sampler_specific_data)
    assert_equal(Encoding::ASCII_8BIT, sampler_info.sampler_specific_data.encoding)
  end

  def test_smpl_chunk_with_extra_unused_bytes
    file_name = fixture("valid/with_sample_chunk_with_extra_unused_bytes.wav")
    reader = Reader.new(file_name)
    sampler_info = reader.sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal(1, sampler_info.loops.length)
    assert_equal(0, sampler_info.loops[0].id)
    assert_equal(:backward, sampler_info.loops[0].type)
    assert_equal(0, sampler_info.loops[0].start_sample_frame)
    assert_equal(0, sampler_info.loops[0].end_sample_frame)
    assert_equal(0.5, sampler_info.loops[0].fraction)
    assert_equal(1, sampler_info.loops[0].play_count)
    assert_equal("\x04\x01\x05", sampler_info.sampler_specific_data)
    assert_equal(Encoding::ASCII_8BIT, sampler_info.sampler_specific_data.encoding)

    # Data chunk should be queued correctly and not raise an error, despite extra bytes
    # at end of `smpl` chunk.
    buffer = reader.read(1)
    assert_equal([[-10000, -10000]], buffer.samples)
  end

  def test_smpl_chunk_no_loops
    file_name = fixture("valid/with_sample_chunk_no_loops.wav")
    sampler_info = Reader.new(file_name).sampler_info

    assert_equal(0, sampler_info.manufacturer_id)
    assert_equal(0, sampler_info.product_id)
    assert_equal(0, sampler_info.sample_nanoseconds)
    assert_equal(60, sampler_info.midi_note)
    assert_equal(50.0, sampler_info.fine_tuning_cents)
    assert_equal(0, sampler_info.smpte_format)
    assert_equal(0, sampler_info.smpte_offset.hours)
    assert_equal(0, sampler_info.smpte_offset.minutes)
    assert_equal(0, sampler_info.smpte_offset.seconds)
    assert_equal(0, sampler_info.smpte_offset.frames)
    assert_equal([], sampler_info.loops)
    assert_equal("", sampler_info.sampler_specific_data)
  end

private

  def read_file(file_name, buffer_size, format=nil)
    buffers = []
    reader = Reader.new(fixture(file_name), format)

    begin
      while true do
        buffers << reader.read(buffer_size)
      end
    rescue EOFError
      reader.close
    end

    buffers
  end

  def fixture(fixture_name)
    "#{FIXTURE_ROOT_PATH}/#{fixture_name}"
  end

  def string_io_from_file(file_name)
    file_contents = File.read(file_name)

    StringIO.new(file_contents)
  end

  def test_duration(expected_hash, duration)
    assert_equal(expected_hash[:hours], duration.hours)
    assert_equal(expected_hash[:minutes], duration.minutes)
    assert_equal(expected_hash[:seconds], duration.seconds)
    assert_equal(expected_hash[:milliseconds], duration.milliseconds)
    assert_equal(expected_hash[:sample_count], duration.sample_frame_count)
  end
end

require 'minitest/autorun'
require 'wavefile.rb'
require 'wavefile_io_test_helper.rb'

include WaveFile

class WriterTest < Minitest::Test
  include WaveFileIOTestHelper

  OUTPUT_FOLDER = "test/fixtures/actual_output"

  def setup
    clean_output_folder
  end

  def test_write_file_with_no_sample_data
    writer = Writer.new("#{OUTPUT_FOLDER}/no_samples.wav", Format.new(:mono, :pcm_8, 44100))
    writer.close

    assert_equal(read_file(:expected, "no_samples.wav"), read_file(:actual, "no_samples.wav"))
  end

  def test_write_basic_file
    [:mono, :stereo].each do |channels|
      [:pcm_8, :pcm_16, :float, :float_32, :float_64].each do |sample_format|
        file_name = "valid_#{channels}_#{sample_format === :float ? :float_32 : sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100)

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file(io_or_file_name, file_name, format)
        end
      end
    end
  end

  def test_write_extensible_file
    # Otherwise non-extensible, but speaker mapping is not the default for 1 channel
    file_name = "valid_extensible_mono_pcm_16_44100_non_default_speaker_mapping.wav"
    format = Format.new(:mono, :pcm_16, 44100, speaker_mapping: [:front_left])

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      write_file(io_or_file_name, file_name, format)
    end


    # Otherwise non-extensible, but speaker mapping is not the default for 2 channels
    file_name = "valid_extensible_stereo_pcm_16_44100_center_right_speakers.wav"
    format = Format.new(:stereo, :pcm_16, 44100, speaker_mapping: [:front_right, :front_center])

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      write_file(io_or_file_name, file_name, format)
    end


    [:mono].each do |channels|
      [:pcm_24, :pcm_32].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_center])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file(io_or_file_name, file_name, format)
        end
      end
    end

    [:stereo].each do |channels|
      [:pcm_24, :pcm_32].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_left, :front_right])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file(io_or_file_name, file_name, format)
        end
      end
    end

    [:tri].each do |channels|
      [:pcm_8, :pcm_16, :pcm_24, :pcm_32, :float, :float_32, :float_64].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format === :float ? :float_32 : sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_left, :front_right, :front_center])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file(io_or_file_name, file_name, format)
        end
      end
    end
  end

  def test_write_basic_file_with_a_block
    [:mono, :stereo].each do |channels|
      [:pcm_8, :pcm_16, :float, :float_32, :float_64].each do |sample_format|
        file_name = "valid_#{channels}_#{sample_format === :float ? :float_32 : sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100)

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file_with_a_block(io_or_file_name, file_name, format)
        end
      end
    end
  end

  def test_write_extensible_file_with_a_block
    [:mono].each do |channels|
      [:pcm_24, :pcm_32].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_center])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file_with_a_block(io_or_file_name, file_name, format)
        end
      end
    end

    [:stereo].each do |channels|
      [:pcm_24, :pcm_32].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_left, :front_right])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file_with_a_block(io_or_file_name, file_name, format)
        end
      end
    end

    [:tri].each do |channels|
      [:pcm_8, :pcm_16, :pcm_24, :pcm_32, :float, :float_32, :float_64].each do |sample_format|
        file_name = "valid_extensible_#{channels}_#{sample_format === :float ? :float_32 : sample_format}_44100.wav"
        format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100, speaker_mapping: [:front_left, :front_right, :front_center])

        ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
          write_file_with_a_block(io_or_file_name, file_name, format)
        end
      end
    end
  end

  def test_write_buffers_of_different_formats
    file_name = "valid_mono_pcm_8_44100.wav"
    format_8bit_mono    = Format.new(:mono,   :pcm_8,  44100)
    format_16_bit_mono  = Format.new(:mono,   :pcm_16, 22050)
    format_16bit_stereo = Format.new(:stereo, :pcm_16, 44100)

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      writer = Writer.new(io_or_file_name, format_8bit_mono)
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 128, format_16bit_stereo))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128,   format_16_bit_mono))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:stereo][:pcm_16] * 24,  format_16bit_stereo))
      writer.close

      assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
    end
  end

  def test_write_file_with_padding_byte
    file_name = "valid_mono_pcm_8_44100_with_padding_byte.wav"
    format = Format.new(:mono, :pcm_8, 44100)

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      writer = Writer.new(io_or_file_name, format)
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, format))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 128, format))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][:pcm_8] * 23 + [88, 88, 88, 88, 167, 167, 167], format))
      writer.close

      assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
    end
  end

  def test_write_no_speaker_mapping
    file_name = "valid_extensible_stereo_pcm_24_44100_no_speaker_mapping.wav"
    format  = Format.new(:stereo, :pcm_24, 44100, speaker_mapping: [:undefined, :undefined])

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      write_file(io_or_file_name, file_name, format)
    end
  end

  def test_write_incomplete_speaker_mapping
    file_name = "valid_extensible_stereo_pcm_24_44100_incomplete_speaker_mapping.wav"
    format  = Format.new(:stereo, :pcm_24, 44100, speaker_mapping: [:front_center])

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      write_file(io_or_file_name, file_name, format)
    end
  end

  def test_write_speaker_mapping_overflow
    speaker_mapping = [
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

    negative = [-10000] * 20
    positive = [10000] * 20
    square_wave_cycle = [negative, negative, negative, negative, positive, positive, positive, positive]

    file_name = "valid_extensible_20_pcm_16_44100_speaker_mapping_overflow.wav"
    format  = Format.new(20, :pcm_16, 44100, speaker_mapping: speaker_mapping)

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      writer = Writer.new(io_or_file_name, format)
      writer.write(Buffer.new(square_wave_cycle * 128, format))
      writer.write(Buffer.new(square_wave_cycle * 128, format))
      writer.write(Buffer.new(square_wave_cycle * 24,  format))
      writer.close

      assert_equal(read_file(:expected, file_name),
                   read_file(:actual, file_name),
                   "Written file doesn't match expected output: #{file_name}")
    end
  end

  def test_write_custom_speaker_mapping
    file_name = "valid_extensible_tri_pcm_16_44100_custom_speaker_mapping.wav"
    format  = Format.new(3, :pcm_16, 44100, speaker_mapping: [:back_left, :side_right, :top_back_left])

    ["#{OUTPUT_FOLDER}/#{file_name}", StringIO.new].each do |io_or_file_name|
      write_file(io_or_file_name, file_name, format)
    end
  end

  def test_close_when_constructed_from_file_name
    writer = Writer.new("#{OUTPUT_FOLDER}/closed_test.wav", Format.new(:mono, :pcm_16, 44100))
    assert_equal(false, writer.closed?)
    writer.close
    assert(writer.closed?)
  end

  def test_close_when_constructed_from_io
    io = StringIO.new
    assert_equal(false, io.closed?)
    assert_equal(0, io.pos)

    writer = Writer.new(io, Format.new(:mono, :pcm_16, 44100))
    assert_equal(false, writer.closed?)

    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][:pcm_16] * 128, Format.new(:mono, :pcm_16, 44100)))

    writer.close
    assert(writer.closed?)

    assert_equal(false, io.closed?)
    assert_equal(2092, io.pos)    # 44 bytes for header, plus 2 bytes per sample, with 8 * 128 samples
    io.close
  end

  def test_attempt_to_write_after_close
    format = Format.new(:mono, :pcm_8, 44100)

    ["#{OUTPUT_FOLDER}/write_after_close.wav", StringIO.new].each do |io_or_file_name|
      writer = Writer.new(io_or_file_name, format)
      writer.write(Buffer.new([1, 2, 3, 4], format))
      writer.close

      assert_raises(WriterClosedError) { writer.write(Buffer.new([5, 6, 7, 8], format)) }
    end
  end

  def test_double_close
    format = Format.new(:mono, :pcm_8, 44100)

    ["#{OUTPUT_FOLDER}/double_close.wav", StringIO.new].each do |io_or_file_name|
      writer = Writer.new(io_or_file_name, format)
      writer.write(Buffer.new([1, 2, 3, 4], format))
      writer.close

      assert_raises(WriterClosedError) { writer.close }
    end
  end

  def test_total_duration
    exhaustively_test do |format_chunk_format, channels, sample_format|
      format = Format.new(CHANNEL_ALIAS[channels], sample_format, 44100)

      ["#{OUTPUT_FOLDER}/total_duration_#{channels}_#{sample_format}_44100.wav", StringIO.new].each do |io_or_file_name|
        writer = Writer.new(io_or_file_name, format)

        assert_equal(0, writer.total_sample_frames)
        duration = writer.total_duration
        assert_equal(0, duration.sample_frame_count)
        assert_equal(44100, duration.sample_rate)
        assert_equal(0, duration.hours)
        assert_equal(0, duration.minutes)
        assert_equal(0, duration.seconds)
        assert_equal(0, duration.milliseconds)

        writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][sample_format] * 2756, format))

        assert_equal(8 * 2756, writer.total_sample_frames)
        duration = writer.total_duration
        assert_equal(8 * 2756, duration.sample_frame_count)
        assert_equal(44100, duration.sample_rate)
        assert_equal(0, duration.hours)
        assert_equal(0, duration.minutes)
        assert_equal(0, duration.seconds)
        assert_equal(499, duration.milliseconds)

        writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][sample_format] * 2756, format))
        writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][sample_format] * 2756, format))

        assert_equal(8 * 2756 * 3, writer.total_sample_frames)
        duration = writer.total_duration
        assert_equal(8 * 2756 * 3, duration.sample_frame_count)
        assert_equal(44100, duration.sample_rate)
        assert_equal(0, duration.hours)
        assert_equal(0, duration.minutes)
        assert_equal(1, duration.seconds)
        assert_equal(499, duration.milliseconds)

        writer.close

        assert_equal(8 * 2756 * 3, writer.total_sample_frames)
        duration = writer.total_duration
        assert_equal(8 * 2756 * 3, duration.sample_frame_count)
        assert_equal(44100, duration.sample_rate)
        assert_equal(0, duration.hours)
        assert_equal(0, duration.minutes)
        assert_equal(1, duration.seconds)
        assert_equal(499, duration.milliseconds)
      end
    end
  end

  # Cause an exception within the block passed to Writer.new, to prove
  # that close is still called (due to an ensure statement in Writer.new).
  def test_exception_with_block
    format = Format.new(:mono, :pcm_8, 44100)
    samples = [1, 2, 3, 4, 5, 6]

    ["#{OUTPUT_FOLDER}/exception_with_block.wav", StringIO.new].each do |io_or_file_name|
      Writer.new(io_or_file_name, format) do |writer|
        begin
          writer.write(Buffer.new(samples, format))
          1 / 0 # cause divide-by-zero exception
        rescue
          # catch the exception and ignore, so test passes
        end
      end

      reader = Reader.new("#{OUTPUT_FOLDER}/exception_with_block.wav")
      assert_equal(samples.size, reader.total_sample_frames)
    end
  end

private

  def read_file(type, file_name)
    if type == :expected
      fixture_folder = 'wave/valid'
    elsif type == :actual
      fixture_folder = 'actual_output'
    else
      raise 'Invalid fixture type'
    end

    # For Windows compatibility with binary files, File.read is not directly used
    File.open("test/fixtures/#{fixture_folder}/#{file_name}", "rb") {|f| f.read }
  end

  def clean_output_folder
    # Make the folder if it doesn't already exist
    Dir.mkdir(OUTPUT_FOLDER) unless File.exist?(OUTPUT_FOLDER)

    dir = Dir.new(OUTPUT_FOLDER)
    file_names = dir.entries
    file_names.each do |file_name|
      if(file_name != "." && file_name != "..")
        File.delete("#{OUTPUT_FOLDER}/#{file_name}")
      end
    end
  end

  def write_file(io_or_file_name, file_name, format)
    if format.channels == 1
      channel_label = :mono
    elsif format.channels == 2
      channel_label = :stereo
    elsif format.channels == 3
      channel_label = :tri
    end
    sample_format = "#{format.sample_format}_#{format.bits_per_sample}".to_sym

    writer = Writer.new(io_or_file_name, format)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channel_label][sample_format] * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channel_label][sample_format] * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channel_label][sample_format] * 24, format))
    writer.close

    if io_or_file_name.is_a?(StringIO)
      io_or_file_name.rewind
      actual_file = io_or_file_name.read.force_encoding("ASCII-8BIT")
    else
      actual_file = read_file(:actual, file_name)
    end
    expected_file = read_file(:expected, file_name)

    assert_equal(expected_file,
                 actual_file,
                 "Written file doesn't match expected output: #{file_name}")
  end

  def write_file_with_a_block(io_or_file_name, file_name, format)
    if format.channels == 1
      channel_label = :mono
    elsif format.channels == 2
      channel_label = :stereo
    elsif format.channels == 3
      channel_label = :tri
    end
    sample_format = "#{format.sample_format}_#{format.bits_per_sample}".to_sym

    writer = Writer.new(io_or_file_name, format) do |w|
      4.times do
        w.write(Buffer.new(SQUARE_WAVE_CYCLE[channel_label][sample_format] * 70, format))
      end
    end

    if io_or_file_name.is_a?(StringIO)
      io_or_file_name.rewind
      actual_file = io_or_file_name.read.force_encoding("ASCII-8BIT")
    else
      actual_file = read_file(:actual, file_name)
    end
    expected_file = read_file(:expected, file_name)

    assert_equal(actual_file,
                 expected_file,
                 "Written file doesn't match expected output: #{file_name}")
    assert(writer.closed?)
  end
end

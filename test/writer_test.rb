require 'test/unit'
require 'wavefile.rb'
require 'wavefile_io_test_helper.rb'

include WaveFile

class WriterTest < Test::Unit::TestCase
  include WaveFileIOTestHelper

  OUTPUT_FOLDER = "test/fixtures/actual_output"

  def setup
    clean_output_folder
  end

  def test_write_file_with_no_sample_data
    writer = Writer.new("#{OUTPUT_FOLDER}/no_samples.wav", Format.new(1, 8, 44100))
    writer.close

    assert_equal(read_file(:expected, "no_samples.wav"), read_file(:actual, "no_samples.wav"))
  end

  def test_write_basic_file
    exhaustively_test do |channels, bits_per_sample|
      file_name = "valid_#{channels}_#{bits_per_sample}_44100.wav"
      format = Format.new(CHANNEL_ALIAS[channels], bits_per_sample, 44100)

      writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, format))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, format))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 24, format))
      writer.close

      assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
    end
  end

  def test_write_basic_file_with_a_block
    exhaustively_test do |channels, bits_per_sample|
      file_name = "valid_#{channels}_#{bits_per_sample}_44100.wav"
      format = Format.new(CHANNEL_ALIAS[channels], bits_per_sample, 44100)

      writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format) do |writer|
        4.times do
          writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 70, format))
        end
      end

      assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
      assert(writer.closed?)
    end
  end

  def test_write_buffers_of_different_formats
    file_name = "valid_mono_8_44100.wav"
    format_8bit_mono    = Format.new(:mono,   8,  44100)
    format_16_bit_mono  = Format.new(:mono,   16, 22050)
    format_16bit_stereo = Format.new(:stereo, 16, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format_8bit_mono)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:stereo][16] * 128, format_16bit_stereo))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][16] * 128,   format_16_bit_mono))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:stereo][16] * 24,  format_16bit_stereo))
    writer.close

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end

  def test_write_file_with_padding_byte
    file_name = "valid_mono_8_44100_with_padding_byte.wav"
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][8] * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][8] * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE[:mono][8] * 23 + [88, 88, 88, 88, 167, 167, 167], format))
    writer.close

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end

  def test_file_name
    file_name = "#{OUTPUT_FOLDER}/example.wav"

    writer = Writer.new(file_name, Format.new(1, 8, 44100))
    assert_equal("#{OUTPUT_FOLDER}/example.wav", writer.file_name)

    writer.close
    assert_equal("#{OUTPUT_FOLDER}/example.wav", writer.file_name)
  end

  def test_closed?
    writer = Writer.new("#{OUTPUT_FOLDER}/closed_test.wav", Format.new(1, 16, 44100))
    assert_equal(false, writer.closed?)
    writer.close
    assert(writer.closed?)
  end

  def test_attempt_to_write_after_close
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/write_after_close.wav", format)
    writer.write(Buffer.new([1, 2, 3, 4], format))
    writer.close

    assert_raise(IOError) { writer.write(Buffer.new([5, 6, 7, 8], format)) }
  end

  def test_duration_written
    exhaustively_test do |channels, bits_per_sample|
      format = Format.new(CHANNEL_ALIAS[channels], bits_per_sample, 44100)

      writer = Writer.new("#{OUTPUT_FOLDER}/duration_written_#{channels}_#{bits_per_sample}_44100.wav", format)

      duration = writer.duration_written
      assert_equal(0, duration.sample_count)
      assert_equal(44100, duration.sample_rate)
      assert_equal(0, duration.hours)
      assert_equal(0, duration.minutes)
      assert_equal(0, duration.seconds)
      assert_equal(0, duration.milliseconds)

      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 2756, format))

      duration = writer.duration_written
      assert_equal(8 * 2756, duration.sample_count)
      assert_equal(44100, duration.sample_rate)
      assert_equal(0, duration.hours)
      assert_equal(0, duration.minutes)
      assert_equal(0, duration.seconds)
      assert_equal(499, duration.milliseconds)

      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 2756, format))
      writer.write(Buffer.new(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 2756, format))

      duration = writer.duration_written
      assert_equal(8 * 2756 * 3, duration.sample_count)
      assert_equal(44100, duration.sample_rate)
      assert_equal(0, duration.hours)
      assert_equal(0, duration.minutes)
      assert_equal(1, duration.seconds)
      assert_equal(499, duration.milliseconds)

      writer.close

      duration = writer.duration_written
      assert_equal(8 * 2756 * 3, duration.sample_count)
      assert_equal(44100, duration.sample_rate)
      assert_equal(0, duration.hours)
      assert_equal(0, duration.minutes)
      assert_equal(1, duration.seconds)
      assert_equal(499, duration.milliseconds)
    end
  end

private

  def read_file(type, file_name)
    # For Windows compatibility with binary files, File.read is not directly used
    return File.open("test/fixtures/#{type}_output/#{file_name}", "rb") {|f| f.read }
  end

  def clean_output_folder
    # Make the folder if it doesn't already exist
    Dir.mkdir(OUTPUT_FOLDER) unless File.exists?(OUTPUT_FOLDER)

    dir = Dir.new(OUTPUT_FOLDER)
    file_names = dir.entries
    file_names.each do |file_name|
      if(file_name != "." && file_name != "..")
        File.delete("#{OUTPUT_FOLDER}/#{file_name}")
      end
    end
  end
end

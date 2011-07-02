$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class WriterTest < Test::Unit::TestCase
  OUTPUT_FOLDER = "test/fixtures/actual_output"

  SQUARE_WAVE_CYCLE_8BIT_MONO = [88, 88, 88, 88, 167, 167, 167, 167]
  SQUARE_WAVE_CYCLE_8BIT_STEREO = [[88, 88], [88, 88], [88, 88], [88, 88],
                                   [167, 167], [167, 167], [167, 167], [167, 167]]
  SQUARE_WAVE_CYCLE_16BIT_MONO = [-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000]
  SQUARE_WAVE_CYCLE_16BIT_STEREO = [[-10000, -10000], [-10000, -10000], [-10000, -10000], [-10000, -10000],
                                    [10000, 10000], [10000, 10000], [10000, 10000], [10000, 10000]]

  def setup
    clean_output_folder()
  end

  def test_write_file_with_no_sample_data
    writer = Writer.new("#{OUTPUT_FOLDER}/no_samples.wav", Format.new(1, 8, 44100))
    writer.close()
    
    assert_equal(read_file(:expected, "no_samples.wav"), read_file(:actual, "no_samples.wav"))
  end

  def test_write_basic_file
    file_name = "valid_mono_16_44100.wav"
    format = Format.new(1, 16, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_MONO * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_MONO * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_MONO * 24, format))
    writer.close()

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end

  def test_write_buffers_of_different_formats
    file_name = "valid_mono_8_44100.wav"
    format_8bit_mono    = Format.new(:mono,   8,  44100)
    format_16_bit_mono  = Format.new(:mono,   16, 22050)
    format_16bit_stereo = Format.new(:stereo, 16, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format_8bit_mono)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_STEREO * 128, format_16bit_stereo))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_MONO * 128,   format_16_bit_mono))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_16BIT_STEREO * 24,  format_16bit_stereo))
    writer.close()

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end

  def test_write_file_with_padding_byte
    file_name = "valid_mono_8_44100_with_padding_byte.wav"
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_8BIT_MONO * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_8BIT_MONO * 128, format))
    writer.write(Buffer.new(SQUARE_WAVE_CYCLE_8BIT_MONO * 23 + [88, 88, 88, 88, 167, 167, 167], format))
    writer.close()

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end
  
  def test_closed?
    writer = Writer.new("#{OUTPUT_FOLDER}/closed_test.wav", Format.new(1, 16, 44100))
    assert_equal(false, writer.closed?)
    writer.close()
    assert(writer.closed?)
  end

  def test_attempt_to_write_after_close
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/write_after_close.wav", format)
    writer.write(Buffer.new([1, 2, 3, 4], format))
    writer.close()

    assert_raise(IOError) { writer.write(Buffer.new([5, 6, 7, 8], format)) }
  end

private

  def read_file(type, file_name)
    # For Windows compatibility with binary files, File.read() is not directly used
    return File.open("test/fixtures/#{type}_output/#{file_name}", "rb") {|f| f.read() }
  end

  def clean_output_folder()
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

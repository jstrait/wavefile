$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class WriterTest < Test::Unit::TestCase
  OUTPUT_FOLDER = "test/fixtures/actual_output"

  def setup
    clean_output_folder()
  end

  def test_attemp_to_write_after_close
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/write_after_close.wav", format)
    writer.write(Buffer.new([1, 2, 3, 4], format))
    writer.close()

    assert_raise(IOError) { writer.write(Buffer.new([5, 6, 7, 8], format)) }
  end

  def test_no_sample_data
    writer = Writer.new("#{OUTPUT_FOLDER}/no_samples.wav", Format.new(1, 8, 44100))
    writer.close()
    
    assert_equal(read_file(:expected, "no_samples.wav"), read_file(:actual, "no_samples.wav"))
  end

  def test_basic
    file_name = "valid_mono_16_44100.wav"
    format = Format.new(1, 16, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
    writer.write(Buffer.new([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, format))
    writer.write(Buffer.new([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, format))
    writer.write(Buffer.new([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 24, format))
    writer.close()

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
  end

  def test_with_padding_byte
    file_name = "valid_mono_8_44100_with_padding_byte.wav"
    format = Format.new(1, 8, 44100)

    writer = Writer.new("#{OUTPUT_FOLDER}/#{file_name}", format)
    writer.write(Buffer.new([88, 88, 88, 88, 167, 167, 167, 167] * 128, format))
    writer.write(Buffer.new([88, 88, 88, 88, 167, 167, 167, 167] * 128, format))
    writer.write(Buffer.new([88, 88, 88, 88, 167, 167, 167, 167] * 23 + [88, 88, 88, 88, 167, 167, 167], format))
    writer.close()

    assert_equal(read_file(:expected, file_name), read_file(:actual, file_name))
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

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class ReaderTest < Test::Unit::TestCase
  FIXTURE_ROOT_PATH = "test/fixtures"

  def test_nonexistent_file
    assert_raise(Errno::ENOENT) { Reader.new(fixture("i_do_not_exist.wav")) }

    assert_raise(Errno::ENOENT) { Reader.info(fixture("i_do_not_exist.wav")) }
  end

  def test_invalid_formats
    # Reader.new() and Reader.info() should raise the same errors for invalid files,
    # so run the tests for both methods.
    [:new, :info].each do |method_name|
      # File contains 0 bytes
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("empty.wav")) }

      # File consists of "RIFF" and nothing else
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("incomplete_riff_header.wav")) }

      # First 4 bytes in the file are not "RIFF"
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("bad_riff_header.wav")) }

      # The format code in the RIFF header is not "WAVE"
      assert_raise(InvalidFormatError) { Reader.new(fixture("bad_wavefile_format.wav")) }

      # The file consists of just a valid RIFF header
      assert_raise(InvalidFormatError) { Reader.new(fixture("no_format_chunk.wav")) }

      # The format chunk has 0 bytes in it (despite the chunk size being 16)
      assert_raise(InvalidFormatError) { Reader.new(fixture("empty_format_chunk.wav")) }

      # The format chunk has some data, but not all of the minimum required.
      assert_raise(InvalidFormatError) { Reader.new(fixture("insufficient_format_chunk.wav")) }

      # The RIFF header and format chunk are OK, but there is no data chunk
      assert_raise(InvalidFormatError) { Reader.new(fixture("no_data_chunk.wav")) }
    end
  end

  def test_unsupported_formats
    # Audio format is 2, which is not supported
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported_audio_format.wav")) }

    # Bits per sample is 24, which is not supported
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported_bits_per_sample.wav")) }

    # Channel count is 0
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("bad_channel_count.wav")) }

    # Sample rate is 0
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("bad_sample_rate.wav")) }
  end

  def test_read_basic_scenario
    buffers = read_file("valid_16_mono_44100.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, buffers[0].samples)
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, buffers[1].samples)
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 24,  buffers[2].samples)
  end

  def test_read_basic_with_format_conversion
    buffers = read_file("valid_16_mono_44100.wav", 1024, Format.new(:stereo, 8, 22100))

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 128, buffers[0].samples)
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 128, buffers[1].samples)
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 24,  buffers[2].samples)
  end

  def test_each_buffer_basic_scenario
    buffers = []
    reader = Reader.new(fixture("valid_16_mono_44100.wav"))
    reader.each_buffer(1024) {|buffer| buffers << buffer }
    
    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, buffers[0].samples)
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 128, buffers[1].samples)
    assert_equal([-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000] * 24,  buffers[2].samples)
  end

  def test_each_buffer_basic_with_format_conversion
    buffers = []
    reader = Reader.new(fixture("valid_16_mono_44100.wav"), Format.new(:stereo, 8, 22100))
    reader.each_buffer(1024) {|buffer| buffers << buffer }
    
    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 128, buffers[0].samples)
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 128, buffers[1].samples)
    assert_equal(([[88, 88]] * 4 + [[167, 167]] * 4) * 24,  buffers[2].samples)
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
      reader.close()
    end

    return buffers
  end

  def fixture(fixture_name)
    return "#{FIXTURE_ROOT_PATH}/#{fixture_name}"
  end
end

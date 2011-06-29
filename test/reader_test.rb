$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class ReaderTest < Test::Unit::TestCase
  FIXTURE_ROOT_PATH = "test/fixtures"

  def test_nonexistent_file
    assert_raise(Errno::ENOENT) { Reader.new(fixture("i_do_not_exist.wav")) }
  end

  # File contains 0 bytes
  def test_empty_file
    assert_raise(InvalidFormatError) { Reader.new(fixture("empty.wav")) }
  end

  # File consists of "RIFF" and nothing else
  def test_incomplete_riff_header
    assert_raise(InvalidFormatError) { Reader.new(fixture("incomplete_riff_header.wav")) }
  end

  # First 4 bytes in the file are not "RIFF"
  def test_bad_riff_header
    assert_raise(InvalidFormatError) { Reader.new(fixture("bad_riff_header.wav")) }
  end

  # The format code in the RIFF header is not "WAVE"
  def test_bad_wave_format
    assert_raise(InvalidFormatError) { Reader.new(fixture("bad_wavefile_format.wav")) }
  end

  # The file consists of just a valid RIFF header
  def test_no_format_chunk
    assert_raise(InvalidFormatError) { Reader.new(fixture("no_format_chunk.wav")) }
  end

  # The format chunk has 0 bytes in it (despite the chunk size being 16)
  def test_empty_format_chunk
    assert_raise(InvalidFormatError) { Reader.new(fixture("empty_format_chunk.wav")) }
  end

  # The format chunk has some data, but not all of the minimum required.
  def test_insufficient_format_chunk
    assert_raise(InvalidFormatError) { Reader.new(fixture("insufficient_format_chunk.wav")) }
  end

  # The RIFF header and format chunk are OK, but there is no data chunk
  def test_no_data_chunk
    assert_raise(InvalidFormatError) { Reader.new(fixture("no_data_chunk.wav")) }
  end

private

  def fixture(fixture_name)
    return "#{FIXTURE_ROOT_PATH}/#{fixture_name}"
  end
end

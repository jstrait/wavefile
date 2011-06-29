$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class ReaderTest < Test::Unit::TestCase
  FIXTURE_ROOT_PATH = "test/fixtures"

  def test_nonexistent_file
    assert_raise(Errno::ENOENT) { Reader.new(fixture("i_do_not_exist.wav")) }
  end

  def test_invalid_formats
    # File contains 0 bytes
    assert_raise(InvalidFormatError) { Reader.new(fixture("empty.wav")) }

    # File consists of "RIFF" and nothing else
    assert_raise(InvalidFormatError) { Reader.new(fixture("incomplete_riff_header.wav")) }

    # First 4 bytes in the file are not "RIFF"
    assert_raise(InvalidFormatError) { Reader.new(fixture("bad_riff_header.wav")) }

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

private

  def fixture(fixture_name)
    return "#{FIXTURE_ROOT_PATH}/#{fixture_name}"
  end
end

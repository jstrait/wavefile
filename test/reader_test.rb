$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class ReaderTest < Test::Unit::TestCase
  def test_nonexistent_file
    assert_raise(Errno::ENOENT) { Reader.new("test/fixtures/i_do_not_exist.wav") }
  end

  def test_empty_file
    assert_raise(UnsupportedFormatError) { Reader.new("test/fixtures/empty.wav") }
  end

  def test_incomplete_riff_header
    assert_raise(UnsupportedFormatError) { Reader.new("test/fixtures/incomplete_riff_header.wav") }
  end

  def test_bad_riff_header
    assert_raise(UnsupportedFormatError) { Reader.new("test/fixtures/bad_riff_header.wav") }
  end

  def test_bad_wave_format
    assert_raise(UnsupportedFormatError) { Reader.new("test/fixtures/bad_wavefile_format.wav") }
  end

  def test_bad_audio_format
    assert_raise(UnsupportedFormatError) { Reader.new("test/fixtures/bad_audio_format.wav") }
  end
end

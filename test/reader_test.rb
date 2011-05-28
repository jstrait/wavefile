$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class BufferTest < Test::Unit::TestCase
  def test_bad_riff_header
    assert_raise(UnsupportedFormatError) { reader = Reader.new("test/fixtures/bad_riff_header.wav") }
  end

  def test_bad_wave_format
    assert_raise(UnsupportedFormatError) { reader = Reader.new("test/fixtures/bad_wavefile_format.wav") }
  end

  def test_bad_audio_format
    assert_raise(UnsupportedFormatError) { reader = Reader.new("test/fixtures/bad_audio_format.wav") }
  end
end

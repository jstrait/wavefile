$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class InfoTest < Test::Unit::TestCase
  FILE_NAME = "foo.wav"

  def test_basic
    format = Format.new(2, 16, 44100)
    info = Info.new(FILE_NAME, format, 44100)
    
    assert_equal(FILE_NAME, info.file_name)
    assert_equal(2, info.channels)
    assert_equal(16, info.bits_per_sample)
    assert_equal(44100, info.sample_rate)
    assert_equal(88200, info.byte_rate)
    assert_equal(4, info.block_align)
    assert_equal(44100, info.sample_count)
    assert_equal({:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 0}, info.duration)
  end
end


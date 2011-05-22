$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class InfoTest < Test::Unit::TestCase
  FILE_NAME = "foo.wav"
  SECONDS_IN_MINUTE = 60
  SECONDS_IN_HOUR = SECONDS_IN_MINUTE * 60

  def test_basic
    format = Format.new(2, 16, 44100)
    info = Info.new(FILE_NAME, format, 44100)
    
    assert_equal(FILE_NAME, info.file_name)
    assert_equal(2, info.channels)
    assert_equal(16, info.bits_per_sample)
    assert_equal(44100, info.sample_rate)
    assert_equal(176400, info.byte_rate)
    assert_equal(4, info.block_align)
    assert_equal(44100, info.sample_count)
    assert_equal({:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 0}, info.duration)
  end

  def test_duration
    # Test common sample rates (22050 and 44100), and some crazy arbitrary sample rate (12346)
    [22050, 44100, 12346].each do |sample_rate|
      format = Format.new(2, 16, sample_rate)

      info = Info.new(FILE_NAME, format, 0)
      assert_equal({:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 0}, info.duration)

      info = Info.new(FILE_NAME, format, sample_rate / 2)
      assert_equal({:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 500}, info.duration)

      info = Info.new(FILE_NAME, format, sample_rate)
      assert_equal({:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 0}, info.duration)

      info = Info.new(FILE_NAME, format, sample_rate * SECONDS_IN_MINUTE)
      assert_equal({:hours => 0, :minutes => 1, :seconds => 0, :milliseconds => 0}, info.duration)

      info = Info.new(FILE_NAME, format, sample_rate * SECONDS_IN_HOUR)
      assert_equal({:hours => 1, :minutes => 0, :seconds => 0, :milliseconds => 0}, info.duration)

      info = Info.new(FILE_NAME, format, (sample_rate * SECONDS_IN_MINUTE) + sample_rate + (sample_rate / 2))
      assert_equal({:hours => 0, :minutes => 1, :seconds => 1, :milliseconds => 500}, info.duration)
    end
  end
end


$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class WaveFileFormatTest < Test::Unit::TestCase
  def test_byte_rate()
    format = WaveFileFormat.new(1, 8, 44100)
    assert_equal(44100, format.byte_rate)

    format = WaveFileFormat.new(1, 16, 44100)
    assert_equal(88200, format.byte_rate)
  end

  def test_block_align()
    [1, :mono].each do |one_channel|
      format = WaveFileFormat.new(one_channel, 8, 44100)
      assert_equal(1, format.block_align)

      format = WaveFileFormat.new(one_channel, 16, 44100)
      assert_equal(2, format.block_align)
    end

    [2, :stereo].each do |two_channels|
      format = WaveFileFormat.new(two_channels, 8, 44100)
      assert_equal(2, format.block_align)

      format = WaveFileFormat.new(two_channels, 16, 44100)
      assert_equal(4, format.block_align)
    end
  end

  def test_mono?()
    [1, :mono].each do |one_channel|
      format = WaveFileFormat.new(one_channel, 8, 44100)
      assert_equal(true, format.mono?)
      assert_equal(false, format.stereo?)
    end

    [2, :stereo].each do |two_channels|
      format = WaveFileFormat.new(two_channels, 8, 44100)
      assert_equal(false, format.mono?)
      assert_equal(true, format.stereo?)
    end
  end
end

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class FormatTest < Test::Unit::TestCase
  def test_invalid_channels()
    ["dsfsfsdf", :foo, 0, 65536].each do |invalid_channels|
      assert_raise(FormatError) { Format.new(invalid_channels, 16, 44100) }
    end
  end

  def test_invalid_bits_per_sample()
    ["dsfsfsdf", :foo, 0, 12].each do |invalid_bits_per_sample|
      assert_raise(FormatError) { Format.new(1, invalid_bits_per_sample, 44100) }
    end
  end

  def test_byte_rate()
    format = Format.new(1, 8, 44100)
    assert_equal(44100, format.byte_rate)

    format = Format.new(1, 16, 44100)
    assert_equal(88200, format.byte_rate)
  end

  def test_block_align()
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, 8, 44100)
      assert_equal(1, format.block_align)

      format = Format.new(one_channel, 16, 44100)
      assert_equal(2, format.block_align)
    end

    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, 8, 44100)
      assert_equal(2, format.block_align)

      format = Format.new(two_channels, 16, 44100)
      assert_equal(4, format.block_align)
    end
  end

  def test_mono?()
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, 8, 44100)
      assert_equal(true, format.mono?)
      assert_equal(false, format.stereo?)
    end

    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, 8, 44100)
      assert_equal(false, format.mono?)
      assert_equal(true, format.stereo?)
    end
  end
end

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class FormatTest < Test::Unit::TestCase
  def test_valid_channels()
    [1, 2, 3, 4, 65535].each do |valid_channels|
      assert_equal(valid_channels, Format.new(valid_channels, 16, 44100).channels)
    end

    assert_equal(1, Format.new(:mono, 16, 44100).channels)
    assert_equal(2, Format.new(:stereo, 16, 44100).channels)
  end

  def test_invalid_channels()
    ["dsfsfsdf", :foo, 0, -1, 65536].each do |invalid_channels|
      assert_raise(InvalidFormatError) { Format.new(invalid_channels, 16, 44100) }
    end
  end

  def test_valid_bits_per_sample()
    assert_equal(8, Format.new(1, 8, 44100).bits_per_sample)
    assert_equal(16, Format.new(1, 16, 44100).bits_per_sample)
    assert_equal(32, Format.new(1, 32, 44100).bits_per_sample)
  end

  def test_invalid_bits_per_sample()
    ["dsfsfsdf", :foo, 0, 12].each do |invalid_bits_per_sample|
      assert_raise(InvalidFormatError) { Format.new(1, invalid_bits_per_sample, 44100) }
    end
  end

  def test_valid_sample_rate()
    [1, 44100, 4294967296].each do |valid_sample_rate|
      assert_equal(valid_sample_rate, Format.new(1, 16, valid_sample_rate).sample_rate)
    end
  end

  def test_invalid_sample_rate()
    ["dsfsfsdf", :foo, 0, -1, 4294967297].each do |invalid_sample_rate|
      assert_raise(InvalidFormatError) { Format.new(1, 16, invalid_sample_rate) }
    end
  end

  def test_byte_rate()
    format = Format.new(1, 8, 44100)
    assert_equal(44100, format.byte_rate)

    format = Format.new(1, 16, 44100)
    assert_equal(88200, format.byte_rate)

    format = Format.new(1, 32, 44100)
    assert_equal(176400, format.byte_rate)

    format = Format.new(2, 8, 44100)
    assert_equal(88200, format.byte_rate)

    format = Format.new(2, 16, 44100)
    assert_equal(176400, format.byte_rate)

    format = Format.new(2, 32, 44100)
    assert_equal(352800, format.byte_rate)
  end

  def test_block_align()
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, 8, 44100)
      assert_equal(1, format.block_align)

      format = Format.new(one_channel, 16, 44100)
      assert_equal(2, format.block_align)

      format = Format.new(one_channel, 32, 44100)
      assert_equal(4, format.block_align)
    end

    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, 8, 44100)
      assert_equal(2, format.block_align)

      format = Format.new(two_channels, 16, 44100)
      assert_equal(4, format.block_align)

      format = Format.new(two_channels, 32, 44100)
      assert_equal(8, format.block_align)
    end
  end

  def test_mono?()
    [1, :mono].each do |one_channel|
      format = Format.new(one_channel, 8, 44100)
      assert_equal(true, format.mono?)
      assert_equal(false, format.stereo?)
    end
  end

  def test_stereo?()
    [2, :stereo].each do |two_channels|
      format = Format.new(two_channels, 8, 44100)
      assert_equal(false, format.mono?)
      assert_equal(true, format.stereo?)
    end
  end
end

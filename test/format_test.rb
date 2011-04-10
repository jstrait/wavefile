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
    format = WaveFileFormat.new(1, 8, 44100)
    assert_equal(1, format.block_align)

    format = WaveFileFormat.new(1, 16, 44100)
    assert_equal(2, format.block_align)

    format = WaveFileFormat.new(2, 8, 44100)
    assert_equal(2, format.block_align)

    format = WaveFileFormat.new(2, 16, 44100)
    assert_equal(4, format.block_align)
  end

  def test_mono?()
    format = WaveFileFormat.new(1, 8, 44100)
    assert_equal(true, format.mono?)
    assert_equal(false, format.stereo?)

    format = WaveFileFormat.new(2, 8, 44100)
    assert_equal(false, format.mono?)
    assert_equal(true, format.stereo?)
  end
end

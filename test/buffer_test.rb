$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class TestWaveFileBuffer
  def interleave_samples(samples)
    super
  end

  def deinterleave_samples(samples, channels)
    super
  end
end

class WaveFileBufferTest < Test::Unit::TestCase
  def test_convert_buffer_interleaving()
    [:interleaved, :noninterleaved].each do |new_interleaving|
      old_format = WaveFileFormat.new(1, 16, 44100, :interleaved)
      buffer = WaveFileBuffer.new([1, 2, 3, 4], old_format)
      buffer.convert!(WaveFileFormat.new(1, 16, 44100, new_interleaving))
      assert_equal([1, 2, 3, 4], buffer.samples)
    end

    old_format = WaveFileFormat.new(2, 16, 44100, :interleaved)
    buffer = WaveFileBuffer.new([1, 2, 3, 4, 5, 6, 7, 8], old_format)
    buffer.convert!(WaveFileFormat.new(2, 16, 44100, :noninterleaved))
    assert_equal([[1, 2], [3, 4], [5, 6], [7, 8]], buffer.samples)

    old_format = WaveFileFormat.new(2, 16, 44100, :interleaved)
    buffer = WaveFileBuffer.new([1, 2, 3, 4, 5, 6, 7, 8], old_format)
    buffer.convert!(WaveFileFormat.new(2, 16, 44100, :interleaved))
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8], buffer.samples)
  end
end

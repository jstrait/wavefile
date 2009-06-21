$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile'

class WaveFileTest < Test::Unit::TestCase
  def test_initialize

  end
  
  def test_read_empty_file
    assert_raise(StandardError) { w = WaveFile.open("examples/invalid/empty.wav") }
  end
  
  def test_read_nonexistent_file
    assert_raise(Errno::ENOENT) { w = WaveFile.open("examples/invalid/oops.wav") }
  end

  def test_read_valid_file
    w = WaveFile.open("examples/valid/sine-8bit.wav")
    assert_equal(w.num_channels, 1)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
    assert_equal(w.sample_data.length, 44100)
  end
  
  def test_new_file
    w = WaveFile.new(1, 44100, 8)
    assert_equal(w.num_channels, 1)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
  end
  
  def test_mono?
    w = WaveFile.new(1, 44100, 16)
    assert_equal(w.mono?, true)
    assert_equal(w.stereo?, false)
    
    w = WaveFile.open("examples/valid/sine-8bit.wav")
    assert_equal(w.mono?, true)
    assert_equal(w.stereo?, false)
  end
  
  def test_stereo?
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.mono?, false)
    assert_equal(w.stereo?, true)
  end
  
  def test_reverse
    w = WaveFile.new(1, 44100, 16)
    w.sample_data = [1, 2, 3, 4, 5]
    w.reverse
    
    assert_equal(w.sample_data, [5, 4, 3, 2, 1])
  end
end
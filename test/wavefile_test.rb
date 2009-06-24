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
    # Mono
    w = WaveFile.new(1, 44100, 8)
    assert_equal(w.num_channels, 1)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
    
    # Stereo
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.num_channels, 2)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 16)
    assert_equal(w.byte_rate, 176400)
    assert_equal(w.block_align, 4)
  end
  
  def test_sample_data=
    # Mono 8-bit
    w = WaveFile.new(1, 44100, 8)
    w.sample_data = [-1.0, -0.5, 0.0, 0.5, 1.0]
    assert_equal(w.sample_data, [0, 64, 128, 191, 255])
    
    # Mono 16-bit
    w = WaveFile.new(1, 44100, 16)
    w.sample_data = [-1.0, -0.5, 0.0, 0.5, 1.0]
    assert_equal(w.sample_data, [-32768, -16384, 0, 16383, 32767])
    
    # Stereo 8-bit
    w = WaveFile.new(2, 44100, 8)
    w.sample_data = [[-1.0, 1.0], [-0.5, 0.5], [0.0, 0.0], [0.5, -0.5], [1.0, -1.0]]
    assert_equal(w.sample_data, [[0, 255], [64, 191], [128, 128], [191, 64], [255, 0]])
    
    # Stereo 16-bit
    w = WaveFile.new(2, 44100, 16)
    w.sample_data = [[-1.0, 1.0], [-0.5, 0.5], [0.0, 0.0], [0.5, -0.5], [1.0, -1.0]]
    assert_equal(w.sample_data, [[-32768, 32767], [-16384, 16383], [0, 0], [16383, -16384], [32767, -32768]])
  end
  
  def test_mono?
    w = WaveFile.new(1, 44100, 16)
    assert_equal(w.mono?, true)
    
    w = WaveFile.open("examples/valid/sine-8bit.wav")
    assert_equal(w.mono?, true)
    
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.mono?, false)
  end
  
  def test_stereo?
    w = WaveFile.new(1, 44100, 16)
    assert_equal(w.stereo?, false)
    
    w = WaveFile.open("examples/valid/sine-8bit.wav")
    assert_equal(w.stereo?, false)
    
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.stereo?, true)
  end
  
  def test_reverse
    # Mono
    w = WaveFile.new(1, 44100, 16)
    w.sample_data = [1, 2, 3, 4, 5]
    w.reverse
    assert_equal(w.sample_data, [5, 4, 3, 2, 1])
  
    # Stereo
    w = WaveFile.new(2, 44100, 16)
    w.sample_data = [[1, 9], [2, 8], [3, 7], [4, 6], [5, 5]]
    w.reverse
    assert_equal(w.sample_data, [[5, 5], [4, 6], [3, 7], [2, 8], [1, 9]])
  end
end
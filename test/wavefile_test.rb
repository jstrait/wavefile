$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile'

class WaveFileTest < Test::Unit::TestCase
  def test_initialize
    # Valid file without sample data
    w = WaveFile.new(1, 44100, 8)
    assert_equal(w.num_channels, 1)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
    assert_equal(w.sample_data, [])
    
    # Valid file with sample data
    w = WaveFile.new(2, 44100, 16, [[1, 9], [2, 8], [3, 7], [4, 6], [5, 5]])
    assert_equal(w.num_channels, 2)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 16)
    assert_equal(w.byte_rate, 176400)
    assert_equal(w.block_align, 4)
    assert_equal(w.sample_data, [[1, 9], [2, 8], [3, 7], [4, 6], [5, 5]])

    # Valid 32-bit file
    w = WaveFile.new(2, 44100, 32)
    assert_equal(w.bits_per_sample, 32)

    # Invalid bits per sample
    assert_raise(UnsupportedBitsPerSampleError) { w = WaveFile.new(1, 44100, 4) }
    
    # Invalid number of channels
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(:foo, 44100, 16) }
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(0, 44100, 16) }
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(65536, 44100, 16) }
  end
  
  def test_read_empty_file
    assert_raise(StandardError) { w = WaveFile.load("examples/invalid/empty.wav") }
  end
  
  def test_read_nonexistent_file
    assert_raise(Errno::ENOENT) { w = WaveFile.load("examples/invalid/nonexistent.wav") }
  end

  def test_read_valid_file
    # Mono file
    w = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    assert_equal(w.num_channels, 1)
    assert_equal(w.mono?, true)
    assert_equal(w.stereo?, false)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
    assert_equal(w.sample_data.length, 44100)
    # Test that sample array is in format [sample, sample ... sample]
    valid = true
    w.sample_data.each{|sample| valid &&= (sample.class == Fixnum)}
    assert_equal(valid, true)
    
    # Stereo file
    w = WaveFile.load("examples/valid/sine-stereo-8bit.wav")
    assert_equal(w.num_channels, 2)
    assert_equal(w.mono?, false)
    assert_equal(w.stereo?, true)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 88200)
    assert_equal(w.block_align, 2)
    assert_equal(w.sample_data.length, 44100)
    # Test that sample array is in format [[left, right], [left, right] ... [left,right]]
    valid = true
    w.sample_data.each{|sample| valid &&= (sample.class == Array) && (sample.length == 2)}
    assert_equal(valid, true)
    
    w = WaveFile.load("examples/valid/simple_mono_16.wav")
    assert_equal([1, 2, 3, 4, 5, 0, 7, 8, 9, 6], w.sample_data)
    
    w = WaveFile.load("examples/valid/simple_stereo_16.wav")
    assert_equal([[1, 2], [3, 4], [5, 0], [7, 8], [9, 10]], w.sample_data)
    
    w = WaveFile.load("examples/valid/simple_quad_16.wav")
    assert_equal([[1, 2, 3, 4], [5, 6, 7, 8], [9, 0, 11, 12], [13, 14, 15, 16], [17, 18, 19, 20]], w.sample_data)
  end
  
  def test_new_file
    # Mono
    w = WaveFile.new(1, 44100, 8)
    assert_equal(w.num_channels, 1)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 8)
    assert_equal(w.byte_rate, 44100)
    assert_equal(w.block_align, 1)
    
    # Mono
    w = WaveFile.new(:mono, 44100, 8)
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
    
    # Stereo
    w = WaveFile.new(:stereo, 44100, 16)
    assert_equal(w.num_channels, 2)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 16)
    assert_equal(w.byte_rate, 176400)
    assert_equal(w.block_align, 4)
    
    # Quad
    w = WaveFile.new(4, 44100, 16)
    assert_equal(w.num_channels, 4)
    assert_equal(w.sample_rate, 44100)
    assert_equal(w.bits_per_sample, 16)
    assert_equal(w.byte_rate, 352800)
    assert_equal(w.block_align, 8)
  end
  
  def test_normalized_sample_data
    # Mono 8-bit
    w = WaveFile.new(:mono, 44100, 8)
    w.sample_data = [0, 32, 64, 96, 128, 160, 192, 223, 255]
    assert_equal(w.normalized_sample_data, [-1.0, -0.75, -0.5, -0.25, 0.0,
                                            (32.0 / 127.0), (64.0 / 127.0), (95.0 / 127.0), 1.0])
    
    # Mono 16-bit
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8192, 16383, 24575, 32767]
    assert_equal(w.normalized_sample_data, [-1.0, -0.75, -0.5, -0.25, 0.0,
                                            (8192.0 / 32767.0), (16383.0 / 32767.0), (24575.0 / 32767.0), 1.0])
    
    # Mono 32-bit
    w = WaveFile.new(:mono, 44100, 32)
    w. sample_data = [-2147483648, -1610612736, -1073741824, -536870912, 0,
                       536870912, 1073741824, 1610612735, 2147483647]
    assert_equal(w.normalized_sample_data, [-1.0, -0.75, -0.5, -0.25, 0.0,
                                            (536870912.0 / 2147483647.0), (1073741824.0 / 2147483647.0), (1610612735.0 / 2147483647.0), 1.0])
    
    # Stereo 8-bit
    w = WaveFile.new(:stereo, 44100, 8)
    w.sample_data = [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128], [160, 96], [192, 64], [223, 32], [255, 0]]
    assert_equal(w.normalized_sample_data, [[-1.0, 1.0],
                                            [-0.75, (95.0 / 127.0)],
                                            [-0.5, (64.0 / 127.0)],
                                            [-0.25, (32.0 / 127.0)],
                                            [0.0, 0.0],
                                            [(32.0 / 127.0), -0.25],
                                            [(64.0 / 127.0), -0.5],
                                            [(95.0 / 127.0), -0.75],
                                            [1.0, -1.0]])
    
    # Stereo 16-bit
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[-32768, 32767], [-24576, 24575], [-16384, 16384], [-8192, 8192], [0, 0], [8192, -8192], [16384, -16384], [24575, -24576], [32767, -32768]]
    assert_equal(w.normalized_sample_data, [[-1.0, 1.0],
                                            [-0.75, (24575.0 / 32767.0)],
                                            [-0.5, (16384.0 / 32767.0)],
                                            [-0.25, (8192.0 / 32767.0)],
                                            [0.0, 0.0],
                                            [(8192.0 / 32767.0), -0.25],
                                            [(16384.0 / 32767.0), -0.5],
                                            [(24575.0 / 32767.0), -0.75],
                                            [1.0, -1.0]])
    
    # Stereo 32-bit
    w = WaveFile.new(:stereo, 44100, 32)
    w. sample_data = [[-2147483648, 2147483647], [-1610612736, 1610612735], [-1073741824, 1073741824], [-536870912, 536870912], [0, 0],
                      [536870912, -536870912], [1073741824, -1073741824], [1610612735, -1610612736], [2147483647, -2147483648]]
    assert_equal(w.normalized_sample_data, [[-1.0, 1.0], [-0.75, (1610612735.0 / 2147483647.0)], [-0.5, (1073741824.0 / 2147483647.0)], [-0.25, (536870912.0 / 2147483647.0)], [0.0, 0.0],
                                            [(536870912.0 / 2147483647.0), -0.25], [(1073741824.0 / 2147483647.0), -0.5], [(1610612735.0 / 2147483647.0), -0.75], [1.0, -1.0]])
  end
  
  def test_sample_data=
    # Mono 8-bit
    w = WaveFile.new(:mono, 44100, 8)
    w.sample_data = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
    assert_equal(w.sample_data, [0, 32, 64, 96, 128, 160, 192, 223, 255])
    
    # Mono 16-bit
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
    assert_equal(w.sample_data, [-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767])
    
    # Mono 32-bit
    w = WaveFile.new(:mono, 44100, 32)
    w.sample_data = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
    assert_equal(w.sample_data, [-2147483648, -1610612736, -1073741824, -536870912, 0,
                                 536870912, 1073741824, 1610612735, 2147483647])
    
    # Stereo 8-bit
    w = WaveFile.new(:stereo, 44100, 8)
    w.sample_data = [[-1.0, 1.0], [-0.75, 0.75], [-0.5, 0.5], [-0.25, 0.25], [0.0, 0.0],
                     [0.25, -0.25], [0.5, -0.5], [0.75, -0.75], [1.0, -1.0]]
    assert_equal(w.sample_data, [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                                 [160, 96], [192, 64], [223, 32], [255, 0]])
    
    # Stereo 16-bit
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[-1.0, 1.0], [-0.75, 0.75], [-0.5, 0.5], [-0.25, 0.25], [0.0, 0.0],
                     [0.25, -0.25], [0.5, -0.5], [0.75, -0.75], [1.0, -1.0]]
    assert_equal(w.sample_data, [[-32768, 32767], [-24576, 24575], [-16384, 16384], [-8192, 8192], [0, 0],
                                 [8192, -8192], [16384, -16384], [24575, -24576], [32767, -32768]])
    
    # Stereo 32-bit
    w = WaveFile.new(:stereo, 44100, 32)
    w.sample_data = [[-1.0, 1.0], [-0.75, 0.75], [-0.5, 0.5], [-0.25, 0.25], [0.0, 0.0],
                     [0.25, -0.25], [0.5, -0.5], [0.75, -0.75], [1.0, -1.0]]
    assert_equal(w.sample_data, [[-2147483648, 2147483647], [-1610612736, 1610612735], [-1073741824, 1073741824], [-536870912, 536870912], [0, 0],
                                 [536870912, -536870912], [1073741824, -1073741824], [1610612735, -1610612736], [2147483647, -2147483648]])
  end
  
  def test_mono?
    w = WaveFile.new(1, 44100, 16)
    assert_equal(w.mono?, true)
    
    w = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    assert_equal(w.mono?, true)
    
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.mono?, false)
    
    w = WaveFile.new(4, 44100, 16)
    assert_equal(w.mono?, false)
  end
  
  def test_stereo?
    w = WaveFile.new(1, 44100, 16)
    assert_equal(w.stereo?, false)
    
    w = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    assert_equal(w.stereo?, false)
    
    w = WaveFile.new(2, 44100, 16)
    assert_equal(w.stereo?, true)
    
    w = WaveFile.new(4, 44100, 16)
    assert_equal(w.stereo?, false)
  end
  
  def test_reverse
    # Mono
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [1, 2, 3, 4, 5]
    w.reverse
    assert_equal(w.sample_data, [5, 4, 3, 2, 1])
  
    # Stereo
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[1, 9], [2, 8], [3, 7], [4, 6], [5, 5]]
    w.reverse
    assert_equal(w.sample_data, [[5, 5], [4, 6], [3, 7], [2, 8], [1, 9]])
  end
  
  def test_duration()
    sample_rate = 44100
    
    [8, 16, 32].each {|bits_per_sample|
      [:mono, :stereo].each {|num_channels|
        w = WaveFile.new(num_channels, sample_rate, bits_per_sample)
        
        w.sample_data = []
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 0})
        w.sample_data = get_duration_test_samples(num_channels, (sample_rate.to_f / 1000.0).floor)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 0})
        w.sample_data = get_duration_test_samples(num_channels, (sample_rate.to_f / 1000.0).ceil)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 1})
        w.sample_data = get_duration_test_samples(num_channels, sample_rate / 2)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 500})
        w.sample_data = get_duration_test_samples(num_channels, sample_rate - 1)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 0, :milliseconds => 999})
        w.sample_data = get_duration_test_samples(num_channels, sample_rate)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 0})
        w.sample_data = get_duration_test_samples(num_channels, sample_rate * 2)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 2, :milliseconds => 0})
        w.sample_data = get_duration_test_samples(num_channels, (sample_rate / 2) * 3)
        assert_equal(w.duration, {:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 500})
        
        # These tests currently take too long to run...
        #w.sample_data = [].fill(0.0, 0, sample_rate * 60)
        #assert_equal(w.duration, {:hours => 0, :minutes => 1, :seconds => 0, :milliseconds => 0})
        #w.sample_data = [].fill(0.0, 0, sample_rate * 60 * 60)
        #assert_equal(w.duration, {:hours => 1, :minutes => 0, :seconds => 0, :milliseconds => 0})
      }
    }
  end
  
  def get_duration_test_samples(num_channels, num_samples)
    if num_channels == :mono || num_channels == 1
      return [].fill(0.0, 0, num_samples)
    elsif num_channels == :stereo || num_channels == 2
      return [].fill([0.0, 0.0], 0, num_samples)
    else
      return "error"
    end
  end
  
  def test_bits_per_sample=()
    # Set bits_per_sample to invalid value (non-8, 16, or 32)
    w = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    assert_raise(UnsupportedBitsPerSampleError) { w.bits_per_sample = 20 }
    w = WaveFile.new(:mono, 44100, 16)
    assert_raise(UnsupportedBitsPerSampleError) { w.bits_per_sample = 4 }
    
    # Load mono 8 bit mono file, change to 8 bit, still the same
    w_before = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    w_after = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    w_after.bits_per_sample = 8
    assert_equal(w_before.sample_data, w_after.sample_data)
    
    # Load mono 8 bit stereo file, change to 8 bit, still the same
    w_before = WaveFile.load("examples/valid/sine-stereo-8bit.wav")
    w_after = WaveFile.load("examples/valid/sine-stereo-8bit.wav")
    w_after.bits_per_sample = 8
    assert_equal(w_before.sample_data, w_after.sample_data)
    
    # Load mono 16 bit file, change to 16 bit, still the same
    # Load stereo 16 bit file, change to 16 bit, still the same
    
    # Load mono 32 bit file, change to 32 bit, still the same
    # Load stereo 32 bit file, change to 32 bit, still the same
    
    # Create mono 8 bit file, convert to 16 bit
    w = WaveFile.new(:mono, 44100, 8)
    w.sample_data = [0, 32, 64, 96, 128, 160, 192, 223, 255]
    w.bits_per_sample = 16
    assert_equal(w.sample_data, [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767])
    
    # Create mono 8 bit file, convert to 32 bit
    w = WaveFile.new(:mono, 44100, 8)
    w.sample_data = [0, 32, 64, 96, 128, 160, 192, 223, 255]
    w.bits_per_sample = 32
    assert_equal(w.sample_data, [-2147483648, -1610612736, -1073741824, -536870912, 0,
                                 541098242, 1082196484, 1606385405, 2147483647])
    
    # Create stereo 8 bit file, convert to 16 bit
    w = WaveFile.new(:stereo, 44100, 8)
    w.sample_data = [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                    [160, 96], [192, 64], [223, 32], [255, 0]]
    w.bits_per_sample = 16
    assert_equal(w.sample_data, [[-32768, 32767], [-24576, 24511], [-16384, 16513], [-8192, 8256], [0, 0],
                                 [8256, -8192], [16513, -16384], [24511, -24576], [32767, -32768]])
                                 
    # Create stereo 8 bit file, convert to 32 bit
    w = WaveFile.new(:stereo, 44100, 8)
    w.sample_data = [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                    [160, 96], [192, 64], [223, 32], [255, 0]]
    w.bits_per_sample = 32
    assert_equal(w.sample_data, [[-2147483648, 2147483647], [-1610612736, 1606385405], [-1073741824, 1082196484], [-536870912, 541098242], [0, 0],
                                 [541098242, -536870912], [1082196484, -1073741824], [1606385405, -1610612736], [2147483647, -2147483648]])

    # Create mono 16 bit file, convert to 8 bit
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767]
    w.bits_per_sample = 8
    assert_equal(w.sample_data, [0, 32, 64, 96, 128, 160, 192, 223, 255])
    
    # Create mono 16 bit file, convert to 32 bit
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767]
    w.bits_per_sample = 32
    assert_equal(w.sample_data, [-2147483648, -1610612736, -1073741824, -536870912, 0,
                                 541081728, 1082228995, 1606401919, 2147483647])
    
    
    # Create stereo 16 bit file, convert to 8 bit
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[-32768, 32767], [-24576, 24511], [-16384, 16513], [-8192, 8256], [0, 0],
                     [8256, -8192], [16513, -16384], [24511, -24576], [32767, -32768]]
    w.bits_per_sample = 8
    assert_equal(w.sample_data, [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                                 [160, 96], [192, 64], [223, 32], [255, 0]])
    
    # Create stereo 16 bit file, convert to 32 bit
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[-32768, 32767], [-24576, 24511], [-16384, 16513], [-8192, 8256], [0, 0],
                     [8256, -8192], [16513, -16384], [24511, -24576], [32767, -32768]]
    w.bits_per_sample = 32
    assert_equal(w.sample_data, [[-2147483648, 2147483647], [-1610612736, 1606401919], [-1073741824, 1082228995], [-536870912, 541081728], [0, 0],
                                 [541081728, -536870912], [1082228995, -1073741824], [1606401919, -1610612736], [2147483647, -2147483648]])
    
    # Create mono 32 bit file, convert to 8 bit
    w = WaveFile.new(:mono, 44100, 32)
    w.sample_data = [-2147483648, -1610612736, -1073741824, -536870912, 0, 541098242, 1082196484, 1606385405, 2147483647]
    w.bits_per_sample = 8
    assert_equal(w.sample_data, [0, 32, 64, 96, 128, 160, 192, 223, 255])
    
    # Create mono 32 bit file, convert to 16 bit
    w = WaveFile.new(:mono, 44100, 32)
    w.sample_data = [-2147483648, -1610612736, -1073741824, -536870912, 0,
                     541081728, 1082228995, 1606401919, 2147483647]
    w.bits_per_sample = 16
    assert_equal(w.sample_data, [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767])
    
    # Create stereo 32 bit file, convert to 8 bit
    w = WaveFile.new(:stereo, 44100, 32)
    w.sample_data = [[-2147483648, 2147483647], [-1610612736, 1606385405], [-1073741824, 1082196484], [-536870912, 541098242], [0, 0],
                     [541098242, -536870912], [1082196484, -1073741824], [1606385405, -1610612736], [2147483647, -2147483648]]
    w.bits_per_sample = 8
    assert_equal(w.sample_data, [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                                 [160, 96], [192, 64], [223, 32], [255, 0]])
    
    # Create stereo 32 bit file, convert to 16 bit
    w = WaveFile.new(:stereo, 44100, 32)
    w.sample_data = [[-2147483648, 2147483647], [-1610612736, 1606401919], [-1073741824, 1082228995], [-536870912, 541081728], [0, 0],
                     [541081728, -536870912], [1082228995, -1073741824], [1606401919, -1610612736], [2147483647, -2147483648]]
    w.bits_per_sample = 16
    assert_equal(w.sample_data, [[-32768, 32767], [-24576, 24511], [-16384, 16513], [-8192, 8256], [0, 0],
                                 [8256, -8192], [16513, -16384], [24511, -24576], [32767, -32768]])
    
    # Load 8 bit mono, convert to 16 bit, back to 8 bit.
    w_before = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    w_after = WaveFile.load("examples/valid/sine-mono-8bit.wav")
    w_after.bits_per_sample = 16
    assert_not_equal(w_before.sample_data, w_after.sample_data)
    w_after.bits_per_sample = 8
    assert_equal(w_before.sample_data, w_after.sample_data)
    
    # Load 8 bit stereo, convert to 16 bit, back to 8 bit.
    w_before = WaveFile.load("examples/valid/sine-stereo-8bit.wav")
    w_after = WaveFile.load("examples/valid/sine-stereo-8bit.wav")
    w_after.bits_per_sample = 16
    assert_not_equal(w_before.sample_data, w_after.sample_data)
    w_after.bits_per_sample = 8
    assert_equal(w_before.sample_data, w_after.sample_data)
    
    # Load 16 bit mono, convert to 8 bit, back to 16 bit.
    # Load 16 bit stereo, convert to 8 bit, back to 16 bit.
  end
  
  def test_num_channels=()
    # Invalid number of channels
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(:foo, 44100, 16) }
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(0, 44100, 16) }
    assert_raise(InvalidNumChannelsError) { w = WaveFile.new(65536, 44100, 16) }
    
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767]
    w.num_channels = 2
    assert_equal(w.sample_data, [[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                                 [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]])
                                 
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767]
    w.num_channels = 3
    assert_equal(w.sample_data, [[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                                [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]])
                                
    w = WaveFile.new(:stereo, 44100, 16)
    w.sample_data = [[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                     [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]]
    w.num_channels = 1
    assert_equal(w.sample_data, [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767])
    
    w = WaveFile.new(3, 44100, 16)
    w.sample_data = [[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                     [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]]
    w.num_channels = 1
    assert_equal(w.sample_data, [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767])
  end
  
  def test_info()
    ### Instance method
    w = WaveFile.new(:mono, 44100, 16)
    w.sample_data = [-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767]
    expected_info = { :format          => "PCM",
                      :num_channels    => 1,
                      :sample_rate     => 44100,
                      :bits_per_sample => 16,
                      :block_align     => 2,
                      :byte_rate       => 88200,
                      :sample_count    => 9,
                      :duration        => {:hours=>0, :minutes=>0, :seconds=>0, :milliseconds=>0} }
    assert_equal(w.info(), expected_info)
    
    w = WaveFile.new(:stereo, 44100, 8)
    w.sample_data = [[0, 255], [32, 223], [64, 192], [96, 160], [128, 128],
                     [160, 96], [192, 64], [223, 32], [255, 0]]
    expected_info = { :format          => "PCM",
                      :num_channels    => 2,
                      :sample_rate     => 44100,
                      :bits_per_sample => 8,
                      :block_align     => 2,
                      :byte_rate       => 88200,
                      :sample_count    => 9,
                      :duration        => {:hours=>0, :minutes=>0, :seconds=>0, :milliseconds=>0} }
    assert_equal(w.info(), expected_info)
    
    
    ### Class method
    assert_equal(WaveFile.info("examples/valid/sine-stereo-8bit.wav"),
                 { :format          => "PCM",
                   :num_channels    => 2,
                   :sample_rate     => 44100,
                   :bits_per_sample => 8,
                   :block_align     => 2,
                   :byte_rate       => 88200,
                   :sample_count    => 44100,
                   :duration        => {:hours=>0, :minutes=>0, :seconds=>1, :milliseconds=>0} })
                   
    assert_raise(StandardError) { WaveFile.info("examples/invalid/empty.wav") }
  end
end
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class WaveFileBufferTest < Test::Unit::TestCase
  def test_convert_buffer_channels
    b = WaveFileBuffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], WaveFileFormat.new(1, 16, 44100))
    b.convert!(WaveFileFormat.new(2, 16, 44100))
    assert_equal([[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                  [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]],
                 b.samples)

    b = WaveFileBuffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], WaveFileFormat.new(1, 16, 44100))
    b.convert!(WaveFileFormat.new(3, 16, 44100))
    assert_equal([[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                  [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]],
                 b.samples)

    b = WaveFileBuffer.new([[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                            [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]],
                           WaveFileFormat.new(2, 16, 44100))
    b.convert!(WaveFileFormat.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767],
                 b.samples)

    b = WaveFileBuffer.new([[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                            [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]],
                           WaveFileFormat.new(3, 16, 44100))
    b.convert!(WaveFileFormat.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767],
                 b.samples)
  end
end

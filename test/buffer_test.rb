$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class BufferTest < Test::Unit::TestCase
  def test_convert_buffer_channels
    Format::SUPPORTED_BITS_PER_SAMPLE.each do |bits_per_sample|
      [44100, 22050].each do |sample_rate|
        # Assert that not changing the number of channels is a no-op
        b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], b.samples)

        # Mono => Stereo
        b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(2, bits_per_sample, sample_rate))
        assert_equal([[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                      [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]],
                     b.samples)

        # Mono => 3-channel
        b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(3, bits_per_sample, sample_rate))
        assert_equal([[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                      [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]],
                     b.samples)

        # Stereo => Mono
        b = Buffer.new([[-32768, -32768], [-24576, -24576], [-16384, -16384], [-8192, -8192], [0, 0],
                                [8256, 8256], [16513, 16513], [24511, 24511], [32767, 32767]],
                       Format.new(2, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767],
                     b.samples)

        # 3-channel => Mono
        b = Buffer.new([[-32768, -32768, -32768], [-24576, -24576, -24576], [-16384, -16384, -16384], [-8192, -8192, -8192], [0, 0, 0],
                                [8256, 8256, 8256], [16513, 16513, 16513], [24511, 24511, 24511], [32767, 32767, 32767]],
                       Format.new(3, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767],
                     b.samples)
      end
    end
  end
end

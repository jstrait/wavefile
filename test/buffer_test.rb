$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class BufferTest < Test::Unit::TestCase
  def test_convert_buffer_channels
    Format::SUPPORTED_BITS_PER_SAMPLE.each do |bits_per_sample|
      [44100, 22050].each do |sample_rate|
        # Assert that not changing the number of channels is a no-op
        b = Buffer.new([-100, 0, 200], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-100, 0, 200], b.samples)

        # Mono => Stereo
        b = Buffer.new([-100, 0, 200], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(2, bits_per_sample, sample_rate))
        assert_equal([[-100, -100], [0, 0], [200, 200]], b.samples)

        # Mono => 3-channel
        b = Buffer.new([-100, 0, 200], Format.new(1, bits_per_sample, sample_rate))
        b.convert!(Format.new(3, bits_per_sample, sample_rate))
        assert_equal([[-100, -100, -100], [0, 0, 0], [200, 200, 200]], b.samples)

        # Stereo => Mono
        b = Buffer.new([[-100, -100], [0, 0], [200, 50], [8, 1]], Format.new(2, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-100, 0, 125, 4], b.samples)

        # 3-channel => Mono
        b = Buffer.new([[-100, -100, -100], [0, 0, 0], [200, 50, 650], [5, 1, 1], [5, 1, 2]],
                       Format.new(3, bits_per_sample, sample_rate))
        b.convert!(Format.new(1, bits_per_sample, sample_rate))
        assert_equal([-100, 0, 300, 2, 2], b.samples)
      end
    end
  end

  def test_convert_buffer_bits_per_sample
    # Assert that not changing the number of channels is a no-op
    b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], Format.new(1, 16, 44100))
    b.convert!(Format.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8256, 16513, 24511, 32767], b.samples)
  end
end

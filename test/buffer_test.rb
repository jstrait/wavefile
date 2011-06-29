$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'wavefile.rb'

include WaveFile

class BufferTest < Test::Unit::TestCase
  def test_convert
    old_format = Format.new(1, 16, 44100)
    new_format = Format.new(2, 16, 22050)

    old_buffer = Buffer.new([-100, 0, 200], old_format)
    new_buffer = old_buffer.convert(new_format)

    assert_equal([-100, 0, 200], old_buffer.samples)
    assert_equal(1, old_buffer.channels)
    assert_equal(16, old_buffer.bits_per_sample)
    assert_equal(44100, old_buffer.sample_rate)

    assert_equal([[-100, -100], [0, 0], [200, 200]], new_buffer.samples)
    assert_equal(2, new_buffer.channels)
    assert_equal(16, new_buffer.bits_per_sample)
    assert_equal(22050, new_buffer.sample_rate)
  end

  def test_convert!
    old_format = Format.new(1, 16, 44100)
    new_format = Format.new(2, 16, 22050)

    old_buffer = Buffer.new([-100, 0, 200], old_format)
    new_buffer = old_buffer.convert!(new_format)

    assert(old_buffer.equal?(new_buffer))
    assert_equal([[-100, -100], [0, 0], [200, 200]], old_buffer.samples)
    assert_equal(2, old_buffer.channels)
    assert_equal(16, old_buffer.bits_per_sample)
    assert_equal(22050, old_buffer.sample_rate)
  end


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

        # 3-channel => Stereo
        b = Buffer.new([[-100, -100, -100], [1, 2, 3], [200, 50, 650]],
                       Format.new(3, bits_per_sample, sample_rate))
        b.convert!(Format.new(2, bits_per_sample, sample_rate))
        assert_equal([[-100, -100], [1, 2], [200, 50]], b.samples)

        # Unsupported conversion (4-channel => 3-channel)
        b = Buffer.new([[-100, 200, -300, 400], [1, 2, 3, 4]],
                       Format.new(4, bits_per_sample, sample_rate))
        assert_raise(BufferConversionError) { b.convert!(Format.new(3, bits_per_sample, sample_rate)) }
      end
    end
  end

  def test_convert_buffer_bits_per_sample
    # Assert that not changing the number of channels is a no-op
    b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767], Format.new(1, 16, 44100))
    b.convert!(Format.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767], b.samples)

    # 8 => 16, Mono
    b = Buffer.new([0, 32, 64, 96, 128, 160, 192, 223, 255], Format.new(1, 8, 44100))
    b.convert!(Format.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24320, 32512], b.samples)

    # 8 => 32, Mono
    b = Buffer.new([0, 32, 64, 96, 128, 160, 192, 223, 255], Format.new(1, 8, 44100))
    b.convert!(Format.new(1, 32, 44100))
    assert_equal([-2147483648, -1610612736, -1073741824, -536870912, 0, 536870912, 1073741824, 1593835520, 2130706432], b.samples)

    # 16 => 8, Mono
    b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767], Format.new(1, 16, 44100))
    b.convert!(Format.new(1, 8, 44100))
    assert_equal([0, 32, 64, 96, 128, 160, 192, 223, 255], b.samples)

    # 16 => 32, Mono
    b = Buffer.new([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767], Format.new(1, 16, 44100))
    b.convert!(Format.new(1, 32, 44100))
    assert_equal([-2147483648, -1610612736, -1073741824, -536870912, 0, 536870912, 1073741824, 1610547200, 2147418112], b.samples)

    # 32 => 8, Mono
    b = Buffer.new([-2147483648, -1610612736, -1073741824, -536870912, 0, 536870912, 1073741824, 1610612735, 2147483647],
                   Format.new(1, 32, 44100))
    b.convert!(Format.new(1, 8, 44100))
    assert_equal([0, 32, 64, 96, 128, 160, 192, 223, 255], b.samples)

    # 32 => 16, Mono
    b = Buffer.new([-2147483648, -1610612736, -1073741824, -536870912, 0, 536870912, 1073741824, 1610612735, 2147483647],
                   Format.new(1, 32, 44100))
    b.convert!(Format.new(1, 16, 44100))
    assert_equal([-32768, -24576, -16384, -8192, 0, 8192, 16384, 24575, 32767], b.samples)
  end
end

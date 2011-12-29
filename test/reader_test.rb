require 'test/unit'
require 'wavefile.rb'
require 'wavefile_io_test_helper.rb'

include WaveFile

class ReaderTest < Test::Unit::TestCase
  include WaveFileIOTestHelper

  FIXTURE_ROOT_PATH = "test/fixtures"

  
  def test_nonexistent_file
    assert_raise(Errno::ENOENT) { Reader.new(fixture("i_do_not_exist.wav")) }

    assert_raise(Errno::ENOENT) { Reader.info(fixture("i_do_not_exist.wav")) }
  end

  def test_invalid_formats
    # Reader.new() and Reader.info() should raise the same errors for invalid files,
    # so run the tests for both methods.
    [:new, :info].each do |method_name|
      # File contains 0 bytes
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("invalid/empty.wav")) }

      # File consists of "RIFF" and nothing else
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("invalid/incomplete_riff_header.wav")) }

      # First 4 bytes in the file are not "RIFF"
      assert_raise(InvalidFormatError) { Reader.send(method_name, fixture("invalid/bad_riff_header.wav")) }

      # The format code in the RIFF header is not "WAVE"
      assert_raise(InvalidFormatError) { Reader.new(fixture("invalid/bad_wavefile_format.wav")) }

      # The file consists of just a valid RIFF header
      assert_raise(InvalidFormatError) { Reader.new(fixture("invalid/no_format_chunk.wav")) }

      # The format chunk has 0 bytes in it (despite the chunk size being 16)
      assert_raise(InvalidFormatError) { Reader.new(fixture("invalid/empty_format_chunk.wav")) }

      # The format chunk has some data, but not all of the minimum required.
      assert_raise(InvalidFormatError) { Reader.new(fixture("invalid/insufficient_format_chunk.wav")) }

      # The RIFF header and format chunk are OK, but there is no data chunk
      assert_raise(InvalidFormatError) { Reader.new(fixture("invalid/no_data_chunk.wav")) }
    end
  end

  def test_unsupported_formats
    # Audio format is 2, which is not supported
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported/unsupported_audio_format.wav")) }

    # Bits per sample is 24, which is not supported
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported/unsupported_bits_per_sample.wav")) }

    # Channel count is 0
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported/bad_channel_count.wav")) }

    # Sample rate is 0
    assert_raise(UnsupportedFormatError) { Reader.new(fixture("unsupported/bad_sample_rate.wav")) }
  end

  def test_initialize
    exhaustively_test do |channels, bits_per_sample|
      file_name = fixture("valid/valid_#{channels}_#{bits_per_sample}_44100.wav")
      reader = Reader.new(file_name)
      assert_equal(CHANNEL_ALIAS[channels], reader.format.channels)
      assert_equal(bits_per_sample, reader.format.bits_per_sample)
      assert_equal(44100, reader.format.sample_rate)
      assert_equal(false, reader.closed?)
      assert_equal(file_name, reader.file_name)
    end
  end

  def test_read_native_format
    exhaustively_test do |channels, bits_per_sample|
      buffers = read_file("valid/valid_#{channels}_#{bits_per_sample}_44100.wav", 1024)

      assert_equal(3, buffers.length)
      assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, buffers[0].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, buffers[1].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 24,  buffers[2].samples)
    end
  end

  def test_read_with_format_conversion
    buffers = read_file("valid/valid_mono_16_44100.wav", 1024, Format.new(:stereo, 8, 22100))

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 24,  buffers[2].samples)
  end

  def test_read_with_padding_byte
    buffers = read_file("valid/valid_mono_8_44100_with_padding_byte.wav", 1024)

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 191], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][8] * 128, buffers[1].samples)
    assert_equal((SQUARE_WAVE_CYCLE[:mono][8] * 23) + [88, 88, 88, 88, 167, 167, 167], 
                 buffers[2].samples)
  end

  def test_each_buffer_native_format
    exhaustively_test do |channels, bits_per_sample|  
      reader = Reader.new(fixture("valid/valid_#{channels}_#{bits_per_sample}_44100.wav"))

      buffers = []
      reader.each_buffer(1024) {|buffer| buffers << buffer }
    
      assert(reader.closed?)
      assert_equal(3, buffers.length)
      assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, buffers[0].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 128, buffers[1].samples)
      assert_equal(SQUARE_WAVE_CYCLE[channels][bits_per_sample] * 24,  buffers[2].samples)
    end
  end

  def test_each_buffer_with_format_conversion
    reader = Reader.new(fixture("valid/valid_mono_16_44100.wav"), Format.new(:stereo, 8, 22050))
    assert_equal(2, reader.format.channels)
    assert_equal(8, reader.format.bits_per_sample)
    assert_equal(22050, reader.format.sample_rate)

    buffers = []
    reader.each_buffer(1024) {|buffer| buffers << buffer }
    
    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 192], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 128, buffers[1].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:stereo][8] * 24,  buffers[2].samples)
  end

  def test_each_buffer_with_padding_byte
    buffers = []
    reader = Reader.new(fixture("valid/valid_mono_8_44100_with_padding_byte.wav"))
    reader.each_buffer(1024) {|buffer| buffers << buffer }

    assert_equal(3, buffers.length)
    assert_equal([1024, 1024, 191], buffers.map {|buffer| buffer.samples.length })
    assert_equal(SQUARE_WAVE_CYCLE[:mono][8] * 128, buffers[0].samples)
    assert_equal(SQUARE_WAVE_CYCLE[:mono][8] * 128, buffers[1].samples)
    assert_equal((SQUARE_WAVE_CYCLE[:mono][8] * 23) + [88, 88, 88, 88, 167, 167, 167], 
                 buffers[2].samples)
  end

  def test_closed?
    reader = Reader.new(fixture("valid/valid_mono_16_44100.wav"))
    assert_equal(false, reader.closed?)
    reader.close()
    assert(reader.closed?)

    # For Reader.each_buffer()
    reader = Reader.new(fixture("valid/valid_mono_16_44100.wav"))
    assert_equal(false, reader.closed?)
    reader.each_buffer(1024) do |buffer|
      # No-op
    end
    assert_equal(true, reader.closed?)
  end

  def test_read_after_close
    reader = Reader.new(fixture("valid/valid_mono_16_44100.wav"))
    buffer = reader.read(1024)
    reader.close()
    assert_raise(IOError) { reader.read(1024) }
  end

private

  def read_file(file_name, buffer_size, format=nil)
    buffers = []
    reader = Reader.new(fixture(file_name), format)

    begin
      while true do
        buffers << reader.read(buffer_size)
      end
    rescue EOFError
      reader.close()
    end

    return buffers
  end

  def fixture(fixture_name)
    return "#{FIXTURE_ROOT_PATH}/#{fixture_name}"
  end
end

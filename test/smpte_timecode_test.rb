require "minitest/autorun"
require "wavefile"

include WaveFile

class SMPTETimecodeTest < Minitest::Test
  VALID_8_BIT_SIGNED_INTEGER_TEST_VALUES = [0, 1, -1, -128, 127]
  INVALID_8_BIT_SIGNED_INTEGER_TEST_VALUES = ["dsfsfsdf", :foo, -129, 128, 2.5, 2.0, -2.0, [10], nil]
  VALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES = [0, 1, 128, 255]
  INVALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES = ["dsfsfsdf", :foo, -1, 256, 2.5, 2.0, [10], nil]

  def test_missing_keywords
    assert_raises(ArgumentError) { SMPTETimecode.new }
  end

  def test_valid_hours
    VALID_8_BIT_SIGNED_INTEGER_TEST_VALUES.each do |valid_value|
      smpte_timecode = SMPTETimecode.new(hours: valid_value,
                                         minutes: 0,
                                         seconds: 0,
                                         frames: 0)

      assert_equal(valid_value, smpte_timecode.hours)
    end
  end

  def test_invalid_hours
    INVALID_8_BIT_SIGNED_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSMPTETimecodeError) do
        SMPTETimecode.new(hours: invalid_value,
                          minutes: 0,
                          seconds: 0,
                          frames: 0)
      end
    end
  end

  def test_valid_minutes
    VALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |valid_value|
      smpte_timecode = SMPTETimecode.new(hours: 0,
                                         minutes: valid_value,
                                         seconds: 0,
                                         frames: 0)

      assert_equal(valid_value, smpte_timecode.minutes)
    end
  end

  def test_invalid_minutes
    INVALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSMPTETimecodeError) do
        SMPTETimecode.new(hours: 0,
                          minutes: invalid_value,
                          seconds: 0,
                          frames: 0)
      end
    end
  end

  def test_valid_seconds
    VALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |valid_value|
      smpte_timecode = SMPTETimecode.new(hours: 0,
                                         minutes: 0,
                                         seconds: valid_value,
                                         frames: 0)

      assert_equal(valid_value, smpte_timecode.seconds)
    end
  end

  def test_invalid_seconds
    INVALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSMPTETimecodeError) do
        SMPTETimecode.new(hours: 0,
                          minutes: 0,
                          seconds: invalid_value,
                          frames: 0)
      end
    end
  end

  def test_valid_frames
    VALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |valid_value|
      smpte_timecode = SMPTETimecode.new(hours: 0,
                                         minutes: 0,
                                         seconds: 0,
                                         frames: valid_value)

      assert_equal(valid_value, smpte_timecode.frames)
    end
  end

  def test_invalid_frames
    INVALID_8_BIT_UNSIGNED_INTEGER_TEST_VALUES.each do |invalid_value|
      assert_raises(InvalidSMPTETimecodeError) do
        SMPTETimecode.new(hours: 0,
                          minutes: 0,
                          seconds: 0,
                          frames: invalid_value)
      end
    end
  end
end

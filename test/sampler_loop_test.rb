require "minitest/autorun"
require "wavefile"

include WaveFile

class SamplerLoopTest < Minitest::Test
  def test_missing_keywords
    assert_raises(ArgumentError) { SamplerLoop.new }
  end

  def test_valid_id
    [0, 10, 4_294_967_295].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: valid_value,
                                     type: :forward,
                                     start_sample_frame: 0,
                                     end_sample_frame: 0,
                                     fraction: 0.0,
                                     play_count: 0)

      assert_equal(valid_value, sampler_loop.id)
    end
  end

  def test_invalid_id
    ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, [10], nil].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: invalid_value,
                        type: :forward,
                        start_sample_frame: 0,
                        end_sample_frame: 0,
                        fraction: 0.0,
                        play_count: 0)
      end
    end
  end

  def test_valid_type
    [:forward, :alternating, :backward].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: 0,
                                     type: valid_value,
                                     start_sample_frame: 0,
                                     end_sample_frame: 0,
                                     fraction: 0.0,
                                     play_count: 0)

      assert_equal(valid_value, sampler_loop.type)
    end

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: 0,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)
    assert_equal(:forward, sampler_loop.type)

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: 1,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)
    assert_equal(:alternating, sampler_loop.type)

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: 2,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)
    assert_equal(:backward, sampler_loop.type)

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: 3,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)
    assert_equal(3, sampler_loop.type)

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: 4_294_967_295,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)
    assert_equal(4_294_967_295, sampler_loop.type)
  end

  def test_invalid_type
    ["dsfsfsdf", :foo, -1, :alternatin, 4_294_967_296, 2.5, 2.0, [:forward], nil].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: 0,
                        type: invalid_value,
                        start_sample_frame: 0,
                        end_sample_frame: 0,
                        fraction: 0.0,
                        play_count: 0)
      end
    end
  end

  def test_valid_start_sample_frame
    [0, 10, 4_294_967_295].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: 0,
                                     type: :forward,
                                     start_sample_frame: valid_value,
                                     end_sample_frame: 0,
                                     fraction: 0.0,
                                     play_count: 0)

      assert_equal(valid_value, sampler_loop.start_sample_frame)
    end
  end

  def test_invalid_start_sample_frame
    ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, [10], nil].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: 0,
                        type: :forward,
                        start_sample_frame: invalid_value,
                        end_sample_frame: 0,
                        fraction: 0.0,
                        play_count: 0)
      end
    end
  end

  def test_valid_end_sample_frame
    [0, 10, 4_294_967_295].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: 0,
                                     type: :forward,
                                     start_sample_frame: 0,
                                     end_sample_frame: valid_value,
                                     fraction: 0.0,
                                     play_count: 0)

      assert_equal(valid_value, sampler_loop.end_sample_frame)
    end
  end

  def test_invalid_end_sample_frame
    ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, [10], nil].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: 0,
                        type: :forward,
                        start_sample_frame: 0,
                        end_sample_frame: invalid_value,
                        fraction: 0.0,
                        play_count: 0)
      end
    end
  end

  def test_valid_fraction
    [0, 0.0, 0.5, 0.99999999999999, 0.0000000000000001].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: 0,
                                     type: :forward,
                                     start_sample_frame: 0,
                                     end_sample_frame: 0,
                                     fraction: valid_value,
                                     play_count: 0)

      assert_equal(valid_value, sampler_loop.fraction)
    end
  end

  def test_invalid_fraction
    ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, nil, [0.5], 1, 1.0, 1.00000000001, -0.0000000000001].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: 0,
                        type: :forward,
                        start_sample_frame: 0,
                        end_sample_frame: 0,
                        fraction: invalid_value,
                        play_count: 0)
      end
    end
  end

  def test_valid_play_count
    [10, 4_294_967_295, Float::INFINITY].each do |valid_value|
      sampler_loop = SamplerLoop.new(id: 0,
                                     type: :forward,
                                     start_sample_frame: 0,
                                     end_sample_frame: 0,
                                     fraction: 0.0,
                                     play_count: valid_value)

      assert_equal(valid_value, sampler_loop.play_count)
    end

    sampler_loop = SamplerLoop.new(id: 0,
                                   type: :forward,
                                   start_sample_frame: 0,
                                   end_sample_frame: 0,
                                   fraction: 0.0,
                                   play_count: 0)

    assert_equal(Float::INFINITY, sampler_loop.play_count)
  end

  def test_invalid_play_count
    ["dsfsfsdf", :foo, -1, 4_294_967_296, 2.5, 2.0, [10], nil].each do |invalid_value|
      assert_raises(InvalidSamplerLoopError) do
        SamplerLoop.new(id: 0,
                        type: :forward,
                        start_sample_frame: 0,
                        end_sample_frame: 0,
                        fraction: 0.0,
                        play_count: invalid_value)
      end
    end
  end
end

module WaveFileIOTestHelper
  SQUARE_WAVE_CYCLE = {}
  SQUARE_WAVE_CYCLE[:mono] = {}
  SQUARE_WAVE_CYCLE[:mono][8] =    [88, 88, 88, 88, 167, 167, 167, 167]
  SQUARE_WAVE_CYCLE[:mono][16] =   [-10000, -10000, -10000, -10000, 10000, 10000, 10000, 10000]
  SQUARE_WAVE_CYCLE[:mono][32] =   [-1000000000, -1000000000, -1000000000, -1000000000,
                                     1000000000, 1000000000, 1000000000, 1000000000]
  SQUARE_WAVE_CYCLE[:stereo] = {}
  SQUARE_WAVE_CYCLE[:stereo][8] =  [[88, 88], [88, 88], [88, 88], [88, 88],
                                    [167, 167], [167, 167], [167, 167], [167, 167]]
  SQUARE_WAVE_CYCLE[:stereo][16] = [[-10000, -10000], [-10000, -10000], [-10000, -10000], [-10000, -10000],
                                    [10000, 10000], [10000, 10000], [10000, 10000], [10000, 10000]]
  SQUARE_WAVE_CYCLE[:stereo][32] = [[-1000000000, -1000000000], [-1000000000, -1000000000],
                                    [-1000000000, -1000000000], [-1000000000, -1000000000],
                                    [ 1000000000,  1000000000], [ 1000000000,  1000000000],
                                    [ 1000000000,  1000000000], [ 1000000000,  1000000000]]
  
  
  # Executes the given block against different combinations of number of channels and bits per sample.
  def exhaustively_test
    [:mono, :stereo].each do |channels|
      Format::SUPPORTED_BITS_PER_SAMPLE.each do |bits_per_sample|
        yield(channels, bits_per_sample)
      end
    end
  end
end

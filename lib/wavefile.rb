#!/usr/bin/env ruby

=begin
Method and apparatus for reading and writing the Wave file sound format using pure Ruby.
=end

=begin
WAV File Specification
FROM http://ccrma.stanford.edu/courses/422/projects/WaveFormat/
The canonical WAVE format starts with the RIFF header:
0         4   ChunkID          Contains the letters "RIFF" in ASCII form
                               (0x52494646 big-endian form).
4         4   ChunkSize        36 + SubChunk2Size, or more precisely:
                               4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
                               This is the size of the rest of the chunk
                               following this number.  This is the size of the
                               entire file in bytes minus 8 bytes for the
                               two fields not included in this count:
                               ChunkID and ChunkSize.
8         4   Format           Contains the letters "WAVE"
                               (0x57415645 big-endian form).

The "WAVE" format consists of two subchunks: "fmt " and "data":
The "fmt " subchunk describes the sound data's format:
12        4   Subchunk1ID      Contains the letters "fmt "
                               (0x666d7420 big-endian form).
16        4   Subchunk1Size    16 for PCM.  This is the size of the
                               rest of the Subchunk which follows this number.
20        2   AudioFormat      PCM = 1 (i.e. Linear quantization)
                               Values other than 1 indicate some
                               form of compression.
22        2   NumChannels      Mono = 1, Stereo = 2, etc.
24        4   SampleRate       8000, 44100, etc.
28        4   ByteRate         == SampleRate * NumChannels * BitsPerSample/8
32        2   BlockAlign       == NumChannels * BitsPerSample/8
                               The number of bytes for one sample including
                               all channels. I wonder what happens when
                               this number isn't an integer?
34        2   BitsPerSample    8 bits = 8, 16 bits = 16, etc.

The "data" subchunk contains the size of the data and the actual sound:
36        4   Subchunk2ID      Contains the letters "data"
                               (0x64617461 big-endian form).
40        4   Subchunk2Size    == NumSamples * NumChannels * BitsPerSample/8
                               This is the number of bytes in the data.
                               You can also think of this as the size
                               of the read of the subchunk following this
                               number.
44        *   Data             The actual sound data.
=end

class UnsupportedBitsPerSampleError < RuntimeError; end
class InvalidNumChannelsError < RuntimeError; end
class UnloadableWaveFileError < RuntimeError; end

class WaveFile
  WAVEFILE_VERSION = "0.4.0a"
  CHUNK_ID = "RIFF"
  FORMAT = "WAVE"
  FORMAT_CHUNK_ID = "fmt "
  SUB_CHUNK1_SIZE = 16
  PCM = 1
  DATA_CHUNK_ID = "data"
  HEADER_SIZE = 36
  SUPPORTED_BITS_PER_SAMPLE = [8, 16, 32]
  PACK_CODES = {8 => "C*", 16 => "s*", 32 => "V*"}
  MAX_NUM_CHANNELS = 65535
  
  # Format codes from http://www.signalogic.com/index.pl?page=ms_waveform
  #               and http://www.sonicspot.com/guide/wavefiles.html
  AUDIO_FORMAT_CODES = {0 => "Unknown", 1 => "PCM", 2 => "Microsoft ADPCM", 3 => "IEEE floating point",
                        5 => "IBM CVSD", 6 => "ITU G.711 a-law", 7 => "ITU G.711 m-law", 11 => "Intel IMA/DVI ADPCM",
                        16 => "ITU G.723 ADPCM", 17 => "Dialogic OKI ADPCM", 20 => "ITU G.723 ADPCM (Yamaha)",
                        30 => "Dolby AAC", 31 => "Microsoft GSM 6.10", 36 => "Rockwell ADPCM",
                        40 => "ITU G.721 ADPCM", 42 => "Microsoft MSG723", 45 => "ITU-T G.726",
                        49 => "GSM 6.10", 64 => "ITU G.721 ADPCM", 80 => "MPEG", 101 => "IBM m-law",
                        102 => "IBM a-law", 103 => "IBM ADPCM", 65536 => "Experimental"}

  def initialize(num_channels, sample_rate, bits_per_sample, sample_data = [])
    validate_bits_per_sample(bits_per_sample)
    validate_num_channels(num_channels)
    
    if num_channels == :mono
      @num_channels = 1
    elsif num_channels == :stereo
      @num_channels = 2
    else
      @num_channels = num_channels
    end
    @sample_rate = sample_rate
    @bits_per_sample = bits_per_sample
    @sample_data = sample_data
    
    bytes_per_sample = (bits_per_sample / 8)
    @byte_rate = sample_rate * @num_channels * bytes_per_sample
    @block_align = @num_channels * bytes_per_sample
  end
  
  # Returns an instance of WaveFile with the file specified by path loaded into it.
  # Raises an UnloadableWaveFileError if the file is not a Wave file, or is in an unsupported format.
  # Currently, Wave files of the following type can be loaded:
  # * PCM audio format (i.e. an audio format code of 1)
  # * 8, 16, or 32 bits per sample
  def self.load(path)
    file = File.open(path, "rb")
    
    begin
      header = read_header(file)
      errors = validate_header(header)

      if errors == []
        sample_data = read_sample_data(file,
                                       header[:num_channels],
                                       header[:bits_per_sample],
                                       header[:sub_chunk2_size])

        wave_file = self.new(header[:num_channels],
                             header[:sample_rate],
                             header[:bits_per_sample],
                             sample_data)
      else
        error_msg = "#{path} can't be opened, due to the following errors:\n"
        errors.each {|error| error_msg += "  * #{error}\n" }
        raise UnloadableWaveFileError, error_msg
      end
    rescue EOFError
      raise StandardError, "An error occured while reading #{path}."
    ensure
      file.close()
    end
    
    return wave_file    
  end
  
  # <b>DEPRECATED:</b> Please use <tt>load</tt> instead. Will likely be removed in v0.5.0.
  def self.open(path)
    warn "[DEPRECATION] `open` is deprecated. Please use `load` instead."
    self.load(path)
  end

  # Saves the Wave file to the file specified by path.
  def save(path)
    # All numeric values should be saved in little-endian format

    bytes_per_sample = (@bits_per_sample / 8)
    sample_data_size = @sample_data.length * @num_channels * bytes_per_sample

    # Write the header
    header = CHUNK_ID
    header += [HEADER_SIZE + sample_data_size].pack("V")
    header += FORMAT
    header += FORMAT_CHUNK_ID
    header += [SUB_CHUNK1_SIZE].pack("V")
    header += [PCM].pack("v")
    header += [@num_channels].pack("v")
    header += [@sample_rate].pack("V")
    header += [@byte_rate].pack("V")
    header += [@block_align].pack("v")
    header += [@bits_per_sample].pack("v")
    header += DATA_CHUNK_ID
    header += [sample_data_size].pack("V")

    file = File.open(path, "w")
    file.syswrite(header)

    # Write the sample data
    pack_code = PACK_CODES[@bits_per_sample]
    if @num_channels == 1
      file.syswrite(@sample_data.pack(pack_code))
    else
      file.syswrite(@sample_data.flatten.pack(pack_code))
    end

    file.close
  end
  
  # Returns true if this is a monophonic file (i.e., num_channels == 1), false otherwise.
  def mono?()
    return num_channels == 1
  end
  
  # Returns true if this is a stereo file (i.e., num_channels == 2), false otherwise.
  def stereo?()
    return num_channels == 2
  end
  
  # Returns a hash describing the duration of the file's sound, given the current sample data and sample rate.
  # The hash contains an hour, minute, second, and millisecond component.
  # For example if there are 66150 samples and the sample rate is 44100, the following will be returned:
  # <code>{:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 500}</code>
  def duration()
    return WaveFile.calculate_duration(@sample_rate, @sample_data.length)
  end
  
  # Returns the sample data for the sound. For mono files, sample data is returned as a list on integers.
  # For files with more than 1 channel, each sample is represented by an Array containing the sample value
  # for each channel. 
  # * Example mono sample data: <code>[1, 2, 3, 4, 5, 6, 7, 8]</code>
  # * Example stereo sample data: <code>[[1, 2], [3, 4], [5, 6], [7, 8]]</code>
  def sample_data()
    return @sample_data
  end
  
  # Replaces the sample data with new sample data. Sample data should be passed in as an Array, and can
  # either be raw or normalized. If the first item in the array is a Float, the data is assumed to be
  # normalized and each sample should be between -1.0 and 1.0 inclusive. Normalized sample data will
  # automatically be converted to the correct raw format based on the current value of bits_per_sample.
  # If the first item in the array is an Integer, the data is assumed to be raw. In this case, each sample
  # should be within these ranges depending on the current value of bits_per_sample:
  # * 8-bit:  0 to 255
  # * 16-bit: -32768 to 32767
  # * 32-bit: -2147483648 to 2147483647
  def sample_data=(sample_data)
    # TODO: Add validation that samples are within correct range
    
    if sample_data.length > 0 && ((mono? && sample_data[0].class == Float) ||
                                  (!mono? && sample_data[0][0].class == Float))
      if @bits_per_sample == 8
        # Samples in 8-bit wave files are stored as a unsigned byte
        # Effective values are 0 to 255, midpoint at 128
        min_value, max_value, midpoint = 128.0, 127.0, 128
      elsif @bits_per_sample == 16
        # Samples in 16-bit wave files are stored as a signed little-endian short
        # Effective values are -32768 to 32767, midpoint at 0
        min_value, max_value, midpoint = 32768.0, 32767.0, 0
      elsif @bits_per_sample == 32
        min_value, max_value, midpoint = 2147483648.0, 2147483647.0, 0
      end
      
      denormalization_function = lambda do |sample|
        if(sample < 0.0)
          (sample * min_value).round + midpoint
        else
          (sample * max_value).round + midpoint
        end
      end
      
      if mono?
        @sample_data = sample_data.map! &denormalization_function
      else
        # What's going on here? Why can't you use map!() in the inner block?
        @sample_data = sample_data.map! {|sample| sample.map &denormalization_function }
      end
    else
      @sample_data = sample_data
    end
  end
  
  # Returns the sample data for the Wave file, but with each sample converted to a Float between -1.0 and 1.0.
  def normalized_sample_data()    
    if @bits_per_sample == 8
      min_value, max_value, midpoint = 128.0, 127.0, 128
    elsif @bits_per_sample == 16
      min_value, max_value, midpoint = 32768.0, 32767.0, 0
    elsif @bits_per_sample == 32
      min_value, max_value, midpoint = 2147483648.0, 2147483647.0, 0
    end
    
    normalization_function = lambda do |sample|
      sample -= midpoint
      # NOTE: In Ruby 1.8, it is faster to manually convert each sample to a Float. (Ballpark 30%).
      # The opposite is true in Ruby 1.9 - omitting .to_f is ballpark 40% faster. Opting in favor
      # of 1.8 for now, since exepected that more people are currently using it and 1.8 needs all the
      # help it can get performance wise. Might add version check in the future and act accordingly.
      if sample < 0
        (sample.to_f / min_value)
      else
        (sample.to_f / max_value)
      end
    end
    
    if mono?
      normalized_sample_data = @sample_data.map! &normalization_function
    else
      normalized_sample_data = @sample_data.map! {|sample| sample.map! &normalization_function }
    end
    
    return normalized_sample_data
  end
  
  # Changes the WaveFile's number of channels. Number of channels can either be specified by an integer
  # between 1 and MAX_NUM_CHANNELS, or :mono for 1 channel, or :stereo for 2 channels.
  # Calling this method will modify any existing sample data. If a mono file is converted to having 2 or
  # more channels, the sample data will be duplicated for each new channel.
  # * Example of mono to stereo: <code>[1, 2, 3, 4] -> [[1, 1], [2, 2], [3, 3], [4, 4]]</code>
  # If a file with 2 or more channels is changed to mono, each sample will be mixed down to mono by averaging.
  # * Example of stereo to mono: <code>[[10, 0], [27, 13], [-4, 2], [20, -5]] -> [5, 20, -1, 7]</code>
  # Currently, converting from 2 channels to more than 2 channels is unsupported.
  def num_channels=(new_num_channels)
    validate_num_channels(new_num_channels)
    
    if new_num_channels == :mono
      new_num_channels = 1
    elsif new_num_channels == :stereo
      new_num_channels = 2
    end
        
    # The cases of mono -> stereo and vice-versa are handled specially,
    # because those conversion methods are faster than the general methods,
    # and the large majority of wave files are expected to be either mono or stereo.
    # TODO: What about 2 or more channels converted to 2 or more channels?
    if @num_channels == 1 && new_num_channels == 2
      sample_data.map! {|sample| [sample, sample]}
    elsif @num_channels == 2 && new_num_channels == 1
        sample_data.map! {|sample| (sample[0] + sample[1]) / 2}
    elsif @num_channels == 1 && new_num_channels >= 2
      sample_data.map! {|sample| [].fill(sample, 0, new_num_channels)}
    elsif @num_channels >= 2 && new_num_channels == 1
      sample_data.map! {|sample| sample.inject(0) {|sub_sample, sum| sum + sub_sample } / @num_channels }
    elsif @num_channels > 2 && new_num_channels == 2
      sample_data.map! {|sample| [sample[0], sample[1]]}
    end
    
    @num_channels = new_num_channels
  end
  
  # Changes the sound's bits per sample. The sample data will be up or down-sampled as a result.
  # When down-sampling (such as from 16 bits to 8 bits), sound quality can be reduced. However,
  # when up-sampling (such as from 8 bits to 16 bits) sound quality DOES NOT improve.
  # Currently, only 8, 16, and 32 bits per sample are supported.
  def bits_per_sample=(new_bits_per_sample)
    if(new_bits_per_sample == @bits_per_sample)
      return
    end
    validate_bits_per_sample(new_bits_per_sample)
    
    if(@bits_per_sample > new_bits_per_sample)
      positive_factor = ((2 ** @bits_per_sample - 1) - 1.0) / ((2 ** new_bits_per_sample - 1) - 1.0)
    else
      positive_factor = ((2 ** new_bits_per_sample - 1) - 1.0) / ((2 ** @bits_per_sample - 1) - 1.0)
    end
    negative_factor = 2 ** (@bits_per_sample - new_bits_per_sample).abs
    
    # Yikes! These 6 mostly identical branches need to be simplified...
    if(@bits_per_sample == 8 && new_bits_per_sample == 16)
      conversion_func = lambda do |sample|
        if(sample < 128)
          ((sample - 128) * negative_factor)
        else
          ((sample - 128) * positive_factor).round
        end
      end
    elsif(@bits_per_sample == 8 && new_bits_per_sample == 32)
      conversion_func = lambda do |sample|
        if(sample < 128)
          ((sample - 128) * negative_factor)
        else
          ((sample - 128) * positive_factor).round
        end
      end
    elsif(@bits_per_sample == 16 && new_bits_per_sample == 8)
      conversion_func = lambda do |sample|
        if(sample < 0)
          (sample / negative_factor) + 128
        else
          (sample / positive_factor).round + 128
        end
      end
    elsif(@bits_per_sample == 16 && new_bits_per_sample == 32)
      conversion_func = lambda do |sample|
        if(sample < 0)
          sample * negative_factor
        else
          (sample * positive_factor).round
        end
      end
    elsif(@bits_per_sample == 32 && new_bits_per_sample == 8)
      conversion_func = lambda do |sample|
        if(sample < 0)
          (sample / negative_factor) + 128
        else
          (sample / positive_factor).round + 128
        end
      end
    elsif(@bits_per_sample == 32 && new_bits_per_sample == 16)
      conversion_func = lambda do |sample|
        if(sample < 0)
          sample / negative_factor
        else
          (sample / positive_factor).round
        end
      end
    end
    
    if mono?
      @sample_data.map! &conversion_func
    else
      sample_data.map! {|sample| sample.map! &conversion_func }
    end
    
    @bits_per_sample = new_bits_per_sample
  end
  
  # Reverses the current sample data, causing any saved sounds to play backwards.
  def reverse()
    sample_data.reverse!()
  end

  # Returns a hash containing metadata about the WaveFile object. The hash contains the following fields:
  # * Audio format: (always "PCM", since this is currently the only format WaveFile can load)
  # * Number of channels: (1, 2, etc.)
  # * Sample rate: (44100, etc.)
  # * Bits per sample: (8, 16, or 32)
  # * Block align: The number of bytes required for 1 sample over each channel. For example, in a stereo
  #   16-bit file this would be 4 (16 bits * 2 channels == 32 bits == 4 bytes).
  # * Byte rate: TO DO
  # * Sample count: TO DO
  # * Duration: The length in time of the file, in the same format as returned by duration.
  def info()
    return { :format          => "PCM",
             :num_channels    => @num_channels,
             :sample_rate     => @sample_rate,
             :bits_per_sample => @bits_per_sample,
             :block_align     => @block_align,
             :byte_rate       => @byte_rate,
             :sample_count    => @sample_data.length,
             :duration        => self.duration() }
  end

  # Returns a hash containing metadata about the Wave file at path.
  # The hash returned is of the same format as the instance method info.
  # An advantage of this method is that it allows you to retrieve metadata for files that WaveFile is not
  # necessarily able to fully load (for example, because it has an unsupported bits per sample).
  def self.info(path)
    file = File.open(path, "rb")
    
    begin
      header = read_header(file)
    rescue EOFError
      raise StandardError, "An error occured while reading file #{path}."
    ensure
      file.close()
    end
    
    sample_count = header[:sub_chunk2_size] / header[:num_channels] / (header[:bits_per_sample] / 8)
    format = AUDIO_FORMAT_CODES[header[:audio_format]]
    if format == nil
      format = "Unknown code: #{header[:audio_format]}"
    end
    
    return { :format          => format,
             :num_channels    => header[:num_channels],
             :sample_rate     => header[:sample_rate],
             :bits_per_sample => header[:bits_per_sample],
             :block_align     => header[:block_align],
             :byte_rate       => header[:byte_rate],
             :sample_count    => sample_count,
             :duration        => calculate_duration(header[:sample_rate], sample_count) }
  end

  # Returns a formatted String representation of the Wave file metadata.
  def inspect()
    duration = self.duration()
    
    result =  "Channels:        #{@num_channels}\n" +
              "Sample rate:     #{@sample_rate}\n" +
              "Bits per sample: #{@bits_per_sample}\n" +
              "Block align:     #{@block_align}\n" +
              "Byte rate:       #{@byte_rate}\n" +
              "Sample count:    #{@sample_data.length}\n" +
              "Duration:        #{duration[:hours]}h:#{duration[:minutes]}m:#{duration[:seconds]}s:#{duration[:milliseconds]}ms\n"
  end

  attr_reader :num_channels, :bits_per_sample, :byte_rate, :block_align
  attr_accessor :sample_rate
  
private

  def self.read_header(file)
    header = {}
    
    # Read RIFF header
    riff_header = file.sysread(12).unpack("a4Va4")
    header[:chunk_id] = riff_header[0]
    header[:chunk_size] = riff_header[1]
    header[:format] = riff_header[2]
    
    # Read format subchunk
    header[:sub_chunk1_id], header[:sub_chunk1_size] = self.read_to_chunk(file, FORMAT_CHUNK_ID)
    format_subchunk_str = file.sysread(header[:sub_chunk1_size])
    format_subchunk = format_subchunk_str.unpack("vvVVvv")  # Any extra parameters are ignored
    header[:audio_format] = format_subchunk[0]
    header[:num_channels] = format_subchunk[1]
    header[:sample_rate] = format_subchunk[2]
    header[:byte_rate] = format_subchunk[3]
    header[:block_align] = format_subchunk[4]
    header[:bits_per_sample] = format_subchunk[5]
    
    # Read data subchunk
    header[:sub_chunk2_id], header[:sub_chunk2_size] = self.read_to_chunk(file, DATA_CHUNK_ID)
    
    return header
  end

  def self.read_to_chunk(file, expected_chunk_id)
    chunk_id = file.sysread(4)
    chunk_size = file.sysread(4).unpack("V")[0]

    while chunk_id != expected_chunk_id
      # Skip chunk
      file.sysread(chunk_size)
      
      chunk_id = file.sysread(4)
      chunk_size = file.sysread(4).unpack("V")[0]
    end
    
    return chunk_id, chunk_size
  end

  def self.validate_header(header)
    errors = []
    
    unless SUPPORTED_BITS_PER_SAMPLE.member?header[:bits_per_sample]
      errors << "Invalid bits per sample of #{header[:bits_per_sample]}. Only 8, 16, and 32 are supported."
    end
    
    unless (1..MAX_NUM_CHANNELS) === header[:num_channels]
      errors << "Invalid number of channels. Must be between 1 and #{MAX_NUM_CHANNELS}."
    end
    
    unless header[:chunk_id] == CHUNK_ID
      errors << "Unsupported chunk ID: '#{header[:chunk_id]}'"
    end
    
    unless header[:format] == FORMAT
      errors << "Unsupported format: '#{header[:format]}'"
    end
    
    unless header[:sub_chunk1_id] == FORMAT_CHUNK_ID
      errors << "Unsupported chunk id: '#{header[:sub_chunk1_id]}'"
    end
    
    unless header[:audio_format] == PCM
      errors << "Unsupported audio format code: '#{header[:audio_format]}'"
    end
    
    unless header[:sub_chunk2_id] == DATA_CHUNK_ID
      errors << "Unsupported chunk id: '#{header[:sub_chunk2_id]}'"
    end
    
    return errors
  end
  
  # Assumes that file is "queued up" to the first sample
  def self.read_sample_data(file, num_channels, bits_per_sample, sample_data_size)
    data = file.sysread(sample_data_size).unpack(PACK_CODES[bits_per_sample])
    
    if(num_channels > 1)
      num_multichannel_samples = data.length / num_channels
      multichannel_data = Array.new(num_multichannel_samples)
      
      if(num_channels == 2)
        # Files with more than 2 channels are expected to be rare, so if there are 2 channels
        # using a faster specific algorithm instead of a general one.
        num_multichannel_samples.times {|i| multichannel_data[i] = [data.pop(), data.pop()].reverse!() }
      else
        # General algorithm that works for any number of channels, 2 or greater.
        num_multichannel_samples.times do |i|
          sample = Array.new(num_channels)
          num_channels.times {|j| sample[j] = data.pop() }
          multichannel_data[i] = sample.reverse!()
        end
      end

      data = multichannel_data.reverse!()
    end
    
    return data
  end
  
  def self.calculate_duration(sample_rate, total_samples)
    samples_per_millisecond = sample_rate / 1000.0
    samples_per_second = sample_rate
    samples_per_minute = samples_per_second * 60
    samples_per_hour = samples_per_minute * 60
    hours, minutes, seconds, milliseconds = 0, 0, 0, 0
    
    if(total_samples >= samples_per_hour)
      hours = total_samples / samples_per_hour
      total_samples -= samples_per_hour * hours
    end
    
    if(total_samples >= samples_per_minute)
      minutes = total_samples / samples_per_minute
      total_samples -= samples_per_minute * minutes
    end
    
    if(total_samples >= samples_per_second)
      seconds = total_samples / samples_per_second
      total_samples -= samples_per_second * seconds
    end
    
    milliseconds = (total_samples / samples_per_millisecond).floor
    
    return { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
  end
  
  def validate_bits_per_sample(candidate_bits_per_sample)
    unless SUPPORTED_BITS_PER_SAMPLE.member?(candidate_bits_per_sample)
      raise UnsupportedBitsPerSampleError,
            "Bits per sample of #{candidate_bits_per_sample} is unsupported. " +
            "Only #{SUPPORTED_BITS_PER_SAMPLE.inspect} are supported."
    end
  end
  
  def validate_num_channels(candidate_num_channels)
    unless candidate_num_channels == :mono   ||
           candidate_num_channels == :stereo ||
           (1..MAX_NUM_CHANNELS) === candidate_num_channels
      raise InvalidNumChannelsError, "Invalid number of channels. Must be between 1 and #{MAX_NUM_CHANNELS}."
    end
  end
end
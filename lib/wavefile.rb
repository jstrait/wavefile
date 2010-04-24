#!/usr/bin/env ruby

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

class WaveFile
  WAVEFILE_VERSION = "0.4.0a"
  CHUNK_ID = "RIFF"
  FORMAT = "WAVE"
  FORMAT_CHUNK_ID = "fmt "
  SUB_CHUNK1_SIZE = 16
  PCM = 1
  DATA_CHUNK_ID = "data"
  HEADER_SIZE = 36
  SUPPORTED_BITS_PER_SAMPLE = [8, 16]

  def initialize(num_channels, sample_rate, bits_per_sample, sample_data = [])
    validate_bits_per_sample(bits_per_sample)
    
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
  
  def self.open(path)
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
        raise StandardError, error_msg
      end
    rescue EOFError
      raise StandardError, "An error occured while reading #{path}."
    ensure
      file.close()
    end
    
    return wave_file
  end

  def save(path)
    # All numeric values should be saved in little-endian format

    sample_data_size = @sample_data.length * @num_channels * (@bits_per_sample / 8)

    # Write the header
    file_contents = CHUNK_ID
    file_contents += [HEADER_SIZE + sample_data_size].pack("V")
    file_contents += FORMAT
    file_contents += FORMAT_CHUNK_ID
    file_contents += [SUB_CHUNK1_SIZE].pack("V")
    file_contents += [PCM].pack("v")
    file_contents += [@num_channels].pack("v")
    file_contents += [@sample_rate].pack("V")
    file_contents += [@byte_rate].pack("V")
    file_contents += [@block_align].pack("v")
    file_contents += [@bits_per_sample].pack("v")
    file_contents += DATA_CHUNK_ID
    file_contents += [sample_data_size].pack("V")

    # Write the sample data
    if !mono?
      output_sample_data = []
      @sample_data.each{|sample|
        sample.each{|sub_sample|
          output_sample_data << sub_sample
        }
      }
    else
      output_sample_data = @sample_data
    end
    
    if @bits_per_sample == 8
      file_contents += output_sample_data.pack("C*")
    elsif @bits_per_sample == 16
      file_contents += output_sample_data.pack("s*")
    else
      raise StandardError, "Bits per sample is #{@bits_per_samples}, only 8 or 16 are supported"
    end

    file = File.open(path, "w")
    file.syswrite(file_contents)
    file.close
  end
  
  def sample_data()
    return @sample_data
  end
  
  def normalized_sample_data()    
    if @bits_per_sample == 8
      min_value = 128.0
      max_value = 127.0
      midpoint = 128
    elsif @bits_per_sample == 16
      min_value = 32768.0
      max_value = 32767.0
      midpoint = 0
    else
      raise StandardError, "Bits per sample is #{@bits_per_samples}, only 8 or 16 are supported"
    end
    
    if mono?
      normalized_sample_data = @sample_data.map {|sample|
        sample -= midpoint
        if sample < 0
          sample.to_f / min_value
        else
          sample.to_f / max_value
        end
      }
    else
      normalized_sample_data = @sample_data.map {|sample|
        sample.map {|sub_sample|
          sub_sample -= midpoint
          if sub_sample < 0
            sub_sample.to_f / min_value
          else
            sub_sample.to_f / max_value
          end
        }
      }
    end
    
    return normalized_sample_data
  end
  
  def sample_data=(sample_data)
    if sample_data.length > 0 && ((mono? && sample_data[0].class == Float) ||
                                  (!mono? && sample_data[0][0].class == Float))
      if @bits_per_sample == 8
        # Samples in 8-bit wave files are stored as a unsigned byte
        # Effective values are 0 to 255, midpoint at 128
        min_value = 128.0
        max_value = 127.0
        midpoint = 128
      elsif @bits_per_sample == 16
        # Samples in 16-bit wave files are stored as a signed little-endian short
        # Effective values are -32768 to 32767, midpoint at 0
        min_value = 32768.0
        max_value = 32767.0
        midpoint = 0
      else
        raise StandardError, "Bits per sample is #{@bits_per_samples}, only 8 or 16 are supported"
      end
      
      if mono?
        @sample_data = sample_data.map {|sample|
          if(sample < 0.0)
            (sample * min_value).round + midpoint
          else
            (sample * max_value).round + midpoint
          end
        }
      else
        @sample_data = sample_data.map {|sample|
          sample.map {|sub_sample|
            if(sub_sample < 0.0)
              (sub_sample * min_value).round + midpoint
            else
              (sub_sample * max_value).round + midpoint
            end
          }
        }
      end
    else
      @sample_data = sample_data
    end
  end

  # Returns true if this is a monophonic file (i.e., it has 1 channel), false otherwise.
  def mono?()
    return num_channels == 1
  end
  
  # Returns true if this is a stereo file (i.e., it has 2 channels), false otherwise.
  def stereo?()
    return num_channels == 2
  end
  
  # Reverses the current sample data, causing any saved sounds to play backwards.
  def reverse()
    sample_data.reverse!()
  end
  
  # Returns a hash describing the duration of the file's sound, given the current sample data and sample rate.
  # The hash contains an hour, minute, second, and millisecond component.
  # For example if there are 66150 samples and the sample rate is 44100, the following will be returned:
  # {:hours => 0, :minutes => 0, :seconds => 1, :milliseconds => 500}
  def duration()
    return WaveFile.calculate_duration(@sample_rate, @sample_data.length)
  end

  def bits_per_sample=(new_bits_per_sample)
    validate_bits_per_sample(new_bits_per_sample)
    
    if @bits_per_sample == 16 && new_bits_per_sample == 8
      conversion_func = lambda {|sample|
        if(sample < 0)
          (sample / 256) + 128
        else
          # Faster to just divide by integer 258?
          (sample / 258.007874015748031).round + 128
        end
      }

      if mono?
        @sample_data.map! &conversion_func
      else
        sample_data.map! {|sample| sample.map! &conversion_func }
      end
    elsif @bits_per_sample == 8 && new_bits_per_sample == 16
      conversion_func = lambda {|sample|
        sample -= 128
        if(sample < 0)
          sample * 256
        else
          # Faster to just multiply by integer 258?
          (sample * 258.007874015748031).round
        end
      }
      
      if mono?
        @sample_data.map! &conversion_func
      else
        sample_data.map! {|sample| sample.map! &conversion_func }
      end
    end
    
    @bits_per_sample = new_bits_per_sample
  end
  
  def num_channels=(new_num_channels)
    if new_num_channels == :mono
      new_num_channels = 1
    elsif new_num_channels == :stereo
      new_num_channels = 2
    end
    
    # The cases of mono -> stereo and vice-versa are handled specially,
    # because those conversion methods are faster than the general methods,
    # and the large majority of wave files are expected to be either mono or stereo.    
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

  # Returns a hash containing metadata about the WaveFile object.
  def info()
    return { :num_channels    => @num_channels,
             :sample_rate     => @sample_rate,
             :bits_per_sample => @bits_per_sample,
             :block_align     => @block_align,
             :byte_rate       => @byte_rate,
             :sample_count    => @sample_data.length,
             :duration        => self.duration() }
  end

  # Returns a hash containing metadata about the Wave file at path.
  # The hash returned is of the same format as the instance method info.
  # An advantage of this method is that it allows you to retreive metadata for files that WaveFile is not
  # necessarily able to fully open (for example, because it has an unsupported bits per sample).
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
    
    return { :num_channels    => header[:num_channels],
             :sample_rate     => header[:sample_rate],
             :bits_per_sample => header[:bits_per_sample],
             :block_align     => header[:block_align],
             :byte_rate       => header[:byte_rate],
             :sample_count    => sample_count,
             :duration        => calculate_duration(header[:sample_rate], sample_count) }
  end

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
      errors << "Invalid bits per sample of #{header[:bits_per_sample]}. Only 8 or 16 are supported."
    end
    
    unless (1..65535) === header[:num_channels]
      errors << "Invalid number of channels. Must be between 1 and 65535."
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
    if(bits_per_sample == 8)
      data = file.sysread(sample_data_size).unpack("C*")
    elsif(bits_per_sample == 16)
      data = file.sysread(sample_data_size).unpack("s*")
    else
      data = []
    end
    
    if(num_channels > 1)
      multichannel_data = []
      
      i = 0
      while i < data.length
        multichannel_data << data[i...(num_channels + i)]
        i += num_channels
      end
      
      data = multichannel_data
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
    
    return  { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
  end
  
  def validate_bits_per_sample(candidate_bits_per_sample)
    if !SUPPORTED_BITS_PER_SAMPLE.member?(candidate_bits_per_sample)
      raise UnsupportedBitsPerSampleError,
            "Bits per sample of #{candidate_bits_per_sample} is unsupported. " +
            "Only #{SUPPORTED_BITS_PER_SAMPLE.inspect} are supported."
    end
  end
end
require 'wavefile'
include WaveFile

file_name = ARGV[0]
puts "Metadata for #{file_name}:"

begin
  reader = Reader.new(file_name)

  audio_format = reader.native_format.audio_format
  if !reader.native_format.sub_audio_format_guid.nil?
    if reader.native_format.sub_audio_format_guid == SUB_FORMAT_GUID_PCM
      sub_format = " (PCM sub format)"
    elsif reader.native_format.sub_audio_format_guid == SUB_FORMAT_GUID_FLOAT
      sub_format = " (Float sub format)"
    else
      sub_format = " (0x#{reader.native_format.sub_audio_format_guid.unpack("h*")[0]} sub format)"
    end
  end

  puts "  Readable by this gem?  #{reader.readable_format? ? 'Yes' : 'No'}"
  puts "  Audio Format:          #{audio_format}#{sub_format}"
  puts "  Channels:              #{reader.native_format.channels}"
  if reader.native_format.valid_bits_per_sample.nil?
    puts "  Bits per sample:       #{reader.native_format.bits_per_sample}"
  else
    puts "  Bits per sample:       #{reader.native_format.valid_bits_per_sample} (in a #{reader.native_format.bits_per_sample}-bit sample container)"
  end
  puts "  Samples per second:    #{reader.native_format.sample_rate}"
  puts "  Bytes per second:      #{reader.native_format.byte_rate}"
  puts "  Block align:           #{reader.native_format.block_align}"
  puts "  Sample frame count:    #{reader.total_sample_frames}"
  puts "  Speaker mapping:       #{reader.native_format.speaker_mapping.nil? ? 'Not defined' : reader.native_format.speaker_mapping.inspect}"

  unless reader.sample_info.nil?
    puts "  #{reader.sample_info.loop_count} Loops:"
    reader.sample_info.loops.each do |loop|
      puts "    ID: #{loop.id}: #{loop.type} from #{loop.start} to #{loop.end}"
    end
  end

  duration = reader.total_duration
  formatted_duration = duration.hours.to_s.rjust(2, "0") << ":" <<
                       duration.minutes.to_s.rjust(2, "0") << ":" <<
                       duration.seconds.to_s.rjust(2, "0") << ":" <<
                       duration.milliseconds.to_s.rjust(3, "0")
  puts "  Play time:             #{formatted_duration}"
rescue InvalidFormatError
  puts "  Not a valid Wave file!"
end

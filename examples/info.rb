require 'wavefile'
include WaveFile

file_name = ARGV[0]
puts "Metadata for #{file_name}:"

begin
  reader = Reader.new(file_name)

  puts "  Readable by this gem?  #{reader.readable_format? ? 'Yes' : 'No'}"
  puts "  Audio Format:          #{reader.native_format.audio_format}"
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
  puts "  Speaker mapping:       #{reader.native_format.speaker_mapping.nil? ? 'None' : reader.native_format.speaker_mapping.inspect}"

  duration = reader.total_duration
  formatted_duration = duration.hours.to_s.rjust(2, "0") << ":" <<
                       duration.minutes.to_s.rjust(2, "0") << ":" <<
                       duration.seconds.to_s.rjust(2, "0") << ":" <<
                       duration.milliseconds.to_s.rjust(3, "0")
  puts "  Play time:             #{formatted_duration}"
rescue InvalidFormatError
  puts "  Not a valid Wave file!"
end

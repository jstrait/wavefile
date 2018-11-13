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

  duration = reader.total_duration
  formatted_duration = duration.hours.to_s.rjust(2, "0") << ":" <<
                       duration.minutes.to_s.rjust(2, "0") << ":" <<
                       duration.seconds.to_s.rjust(2, "0") << ":" <<
                       duration.milliseconds.to_s.rjust(3, "0")
  puts "  Play time:             #{formatted_duration}"

  unless reader.sample_info.nil?
    puts "  Sampler Info:"
    puts "    Manufacturer ID: #{reader.sample_info.manufacturer_id}"
    puts "    Product ID: #{reader.sample_info.product_id}"
    puts "    Sample Duration: #{reader.sample_info.sample_duration}ns"
    puts "    MIDI Note Number: #{reader.sample_info.midi_note}"
    puts "    Fine Tuning Cents: #{reader.sample_info.fine_tuning_cents}"
    puts "    SMPTE Format: #{reader.sample_info.smpte_format}"
    puts "    SMPTE Offset: #{reader.sample_info.smpte_offset[:hours].to_s.rjust(2, "0")}:#{reader.sample_info.smpte_offset[:minutes].to_s.rjust(2, "0")}:#{reader.sample_info.smpte_offset[:seconds].to_s.rjust(2, "0")} #{reader.sample_info.smpte_offset[:frame_count].to_s.rjust(2, "0")}"
    if reader.sample_info.loops.any?
      puts "    #{reader.sample_info.loops.length} Loop(s):"
      reader.sample_info.loops.each do |loop|
        puts "      ID #{loop.id}: #{loop.type} from sample frame #{loop.start_sample_frame} to sample frame #{loop.end_sample_frame}"
      end
    else
      puts "    No loops."
    end
  end
rescue InvalidFormatError
  puts "  Not a valid Wave file!"
end

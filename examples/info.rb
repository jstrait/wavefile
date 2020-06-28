require 'wavefile'
include WaveFile

file_name = ARGV[0]
if file_name.nil?
  puts "No file name given."
  exit
end

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

  puts "Readable by this gem?  #{reader.readable_format? ? 'Yes' : 'No'}"
  puts "Audio Format:          #{audio_format}#{sub_format}"
  puts "Channels:              #{reader.native_format.channels}"
  if reader.native_format.valid_bits_per_sample.nil?
    puts "Bits per sample:       #{reader.native_format.bits_per_sample}"
  else
    puts "Bits per sample:       #{reader.native_format.valid_bits_per_sample} (in a #{reader.native_format.bits_per_sample}-bit sample container)"
  end
  puts "Samples per second:    #{reader.native_format.sample_rate}"
  puts "Bytes per second:      #{reader.native_format.byte_rate}"
  puts "Block align:           #{reader.native_format.block_align}"
  puts "Sample frame count:    #{reader.total_sample_frames}"
  puts "Speaker mapping:       #{reader.native_format.speaker_mapping.nil? ? 'Not defined' : reader.native_format.speaker_mapping.inspect}"

  duration = reader.total_duration
  formatted_duration = duration.hours.to_s.rjust(2, "0") << ":" <<
                       duration.minutes.to_s.rjust(2, "0") << ":" <<
                       duration.seconds.to_s.rjust(2, "0") << ":" <<
                       duration.milliseconds.to_s.rjust(3, "0")
  puts "Play time:             #{formatted_duration}"

  sampler_info = reader.sampler_info
  unless sampler_info.nil?
    puts "Sampler Info:"
    puts "  Manufacturer ID: #{sampler_info.manufacturer_id}"
    puts "  Product ID: #{sampler_info.product_id}"
    puts "  Sample Duration: #{sampler_info.sample_nanoseconds} nanoseconds"
    puts "  MIDI Note Number: #{sampler_info.midi_note}"
    puts "  Fine Tuning Cents: #{sampler_info.fine_tuning_cents}"
    puts "  SMPTE Format: #{sampler_info.smpte_format}"
    puts "  SMPTE Offset: #{sampler_info.smpte_offset.hours.to_s.rjust(2, "0")}:#{sampler_info.smpte_offset.minutes.to_s.rjust(2, "0")}:#{sampler_info.smpte_offset.seconds.to_s.rjust(2, "0")} #{sampler_info.smpte_offset.frames.to_s.rjust(2, "0")}"
    if sampler_info.sampler_specific_data.nil?
      puts "  Sampler Specific Data: None"
    else
      puts "  Sampler Specific Data: #{sampler_info.sampler_specific_data.bytes}"
    end
    if sampler_info.loops.any?
      puts "  #{sampler_info.loops.length} Loop(s):"
      sampler_info.loops.each do |loop|
        puts "    ID #{loop.id}: #{loop.type} from sample frame #{loop.start_sample_frame} to #{loop.end_sample_frame} (offset fraction #{loop.fraction}), looping #{loop.play_count} times."
      end
    else
      puts "  No loops."
    end
  end
rescue Errno::ENOENT
  puts "File not found!"
rescue InvalidFormatError => error
  puts "Not a valid Wave file! Error message: \"#{error}\""
end

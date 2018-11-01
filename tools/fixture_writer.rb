# This program creates example Wave files that can be used as test fixtures.
# The YAML file input determines what data will be written to the output
# Wave file.
#
# This program intentionally does not try to validate the input, and will
# happily create invalid Wave files. This allows one to create both valid
# and invalid Wave files for testing.

require 'yaml'

FOUR_CC = "a4"
UNSIGNED_INT_8  = "C"
UNSIGNED_INT_16_LITTLE_ENDIAN = "v"
UNSIGNED_INT_32_LITTLE_ENDIAN = "V"
FLOAT_32_LITTLE_ENDIAN = "e"
FLOAT_64_LITTLE_ENDIAN = "E"

CHUNK_HEADER_SIZE_IN_BYTES = 8
RIFF_CHUNK_HEADER_SIZE = 12  # 8 byte FourCC, plus the "WAVE" format code string

SQUARE_WAVE_CYCLE_SAMPLE_FRAMES = 8

class FileWriter
  def initialize(output_file_name)
    @output_file = File.open(output_file_name, "wb")
  end

  def close
    @output_file.close
  end

  def write_value(value, type)
    if type == "24"
      components = [value].pack("l").unpack("CCc")
      components.each do |byte|
        @output_file.write([byte].pack("C"))
      end
    else
      @output_file.write([value].pack(type))
    end
  end

  def write_or_skip(value, type)
    if value == nil
      return
    end

    write_value(value, type)
  end

  def write_or_quit(value, type)
    if value == nil
      close
      exit(0)
    end

    write_value(value, type)
  end
end


yaml_file_name = ARGV[0]
output_file_name = ARGV[1]

chunks = YAML::load(File.read(yaml_file_name))

riff_chunk = chunks["riff_chunk"]
format_chunk = chunks["format_chunk"]
fact_chunk = chunks["fact_chunk"]
junk_chunk = chunks["junk_chunk"]
smpl_chunk = chunks["smpl_chunk"]
data_chunk = chunks["data_chunk"]
SQUARE_WAVE_CYCLE_REPEATS = (data_chunk && data_chunk["cycle_repeats"]) || 0
TOTAL_SAMPLE_FRAMES = SQUARE_WAVE_CYCLE_SAMPLE_FRAMES * SQUARE_WAVE_CYCLE_REPEATS

if riff_chunk["chunk_size"] == "auto"
  format_chunk_size = format_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES
  fact_chunk_size = fact_chunk ? fact_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES : 0
  riff_chunk["chunk_size"] = format_chunk_size + fact_chunk_size + RIFF_CHUNK_HEADER_SIZE + (TOTAL_SAMPLE_FRAMES * format_chunk["block_align"])
end

file_writer = FileWriter.new(output_file_name)


# Write the RIFF chunk
file_writer.write_or_quit(riff_chunk["chunk_id"], FOUR_CC)
file_writer.write_or_quit(riff_chunk["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
file_writer.write_or_quit(riff_chunk["wave_format"], FOUR_CC)

# Write the Format chunk
if format_chunk
  file_writer.write_or_quit(format_chunk["chunk_id"], FOUR_CC)
  file_writer.write_or_quit(format_chunk["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["audio_format"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["channels"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["sample_rate"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["byte_rate"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["block_align"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_quit(format_chunk["bits_per_sample"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(format_chunk["extension_size"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(format_chunk["valid_bits_per_sample"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(format_chunk["speaker_mapping"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  if format_chunk["subformat_guid"]
    format_chunk["subformat_guid"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end
end

if fact_chunk
  file_writer.write_or_quit(fact_chunk["chunk_id"], FOUR_CC)
  file_writer.write_or_quit(fact_chunk["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  if fact_chunk["sample_count"] == "auto"
    file_writer.write_or_quit(TOTAL_SAMPLE_FRAMES, UNSIGNED_INT_32_LITTLE_ENDIAN)
  else
    file_writer.write_or_quit(fact_chunk["sample_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  end
end

# Write a Junk chunk
if junk_chunk
  file_writer.write_or_quit("JUNK", FOUR_CC)
  file_writer.write_or_quit(9, UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit("123456789\000", "a10")
end

# Write a 'smpl' chunk
if smpl_chunk
  file_writer.write_or_quit(smpl_chunk["chunk_id"], FOUR_CC)
  file_writer.write_or_quit(smpl_chunk["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["manufacturer_id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["product_id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["sample_duration"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["unity_note"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["pitch_fraction"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["smpte_format"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["smpte_offset"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["loop_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_quit(smpl_chunk["sampler_data"], UNSIGNED_INT_32_LITTLE_ENDIAN)

  if smpl_chunk["loops"]
    smpl_chunk["loops"].each do |loop|
      file_writer.write_or_quit(loop["id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_quit(loop["type"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_quit(loop["start"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_quit(loop["end"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_quit(loop["fraction"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_quit(loop["play_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
    end
  end
end

# Write the Data chunk
if (data_chunk)
  file_writer.write_or_quit("data", FOUR_CC)
  file_writer.write_or_quit((TOTAL_SAMPLE_FRAMES * format_chunk["block_align"]), UNSIGNED_INT_32_LITTLE_ENDIAN)

  def write_square_wave_samples(file_writer, sample_format, bits_per_sample, channel_format)
    if sample_format == :pcm
      if bits_per_sample == 8
        low_val, high_val, pack_code = 88, 167, UNSIGNED_INT_8
      elsif bits_per_sample == 16
        low_val, high_val, pack_code = -10000, 10000, "s<"
      elsif bits_per_sample == 24
        low_val, high_val, pack_code = -1_000_000, 1_000_000, "24"
      elsif bits_per_sample == 32
        low_val, high_val, pack_code = -1_000_000_000, 1_000_000_000, "l<"
      end
    elsif sample_format == :float
      if bits_per_sample == 32
        low_val, high_val, pack_code = -0.5, 0.5, FLOAT_32_LITTLE_ENDIAN
      elsif bits_per_sample == 64
        low_val, high_val, pack_code = -0.5, 0.5, FLOAT_64_LITTLE_ENDIAN
      end
    end

    if channel_format == "mono"
      channel_count = 1
    elsif channel_format == "stereo"
      channel_count = 2
    elsif channel_format == "tri"
      channel_count = 3
    elsif channel_format.is_a? Integer
      channel_count = channel_format
    else
      channel_count = 0
    end

    SQUARE_WAVE_CYCLE_REPEATS.times do
      channel_count.times do
        file_writer.write_or_quit(low_val,  pack_code)
        file_writer.write_or_quit(low_val,  pack_code)
        file_writer.write_or_quit(low_val,  pack_code)
        file_writer.write_or_quit(low_val,  pack_code)
      end
      channel_count.times do
        file_writer.write_or_quit(high_val, pack_code)
        file_writer.write_or_quit(high_val, pack_code)
        file_writer.write_or_quit(high_val, pack_code)
        file_writer.write_or_quit(high_val, pack_code)
      end
    end
  end

  if format_chunk["audio_format"] == 1
    sample_format = :pcm
  elsif format_chunk["audio_format"] == 3
    sample_format = :float
  elsif format_chunk["audio_format"] == 65534
    if format_chunk["subformat_guid"][0] == 1
      sample_format = :pcm
    elsif format_chunk["subformat_guid"][0] == 3
      sample_format = :float
    end
  end

  write_square_wave_samples(file_writer, sample_format, format_chunk["bits_per_sample"], data_chunk["channel_format"])
end

file_writer.close

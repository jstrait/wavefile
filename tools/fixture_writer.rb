# This program creates example Wave files that can be used as test fixtures.
# The YAML file input determines what data will be written to the output
# Wave file.
#
# This program intentionally does not try to validate the input, and will
# happily create invalid Wave files. This allows one to create both valid
# and invalid Wave files for testing.

require "yaml"

FOUR_CC = "a4"
UNSIGNED_INT_8  = "C"
UNSIGNED_INT_16_LITTLE_ENDIAN = "v"
UNSIGNED_INT_32_LITTLE_ENDIAN = "V"
SIGNED_INT_16_LITTLE_ENDIAN = "s<"
SIGNED_INT_24_LITTLE_ENDIAN = "l<X"
SIGNED_INT_32_LITTLE_ENDIAN = "l<"
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

  def write_value(value, pack_template)
    if value.nil?
      raise "Unexpected attempt to write a nil value"
    end

    @output_file.write([value].pack(pack_template))
  end

  def write_or_skip(value, pack_template)
    if value == nil
      return
    end

    write_value(value, pack_template)
  end
end

def write_riff_chunk(file_writer, config)
  file_writer.write_or_skip(config["chunk_id"], FOUR_CC)
  file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["wave_format"], FOUR_CC)
end

def write_format_chunk(file_writer, config)
  file_writer.write_or_skip(config["chunk_id"], FOUR_CC)
  file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["audio_format"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["channels"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["sample_rate"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["byte_rate"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["block_align"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["bits_per_sample"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["extension_size"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["valid_bits_per_sample"], UNSIGNED_INT_16_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["speaker_mapping"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  if config["subformat_guid"]
    config["subformat_guid"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end

  if config["extra_bytes"]
    config["extra_bytes"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end
end

def write_fact_chunk(file_writer, config)
  file_writer.write_or_skip(config["chunk_id"], FOUR_CC)
  file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  if config["sample_count"] == "auto"
    file_writer.write_or_skip(TOTAL_SAMPLE_FRAMES, UNSIGNED_INT_32_LITTLE_ENDIAN)
  else
    file_writer.write_or_skip(config["sample_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  end
end

def write_junk_chunk(file_writer, config)
  file_writer.write_or_skip(config["chunk_id"], FOUR_CC)
  file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  if config["data"]
    config["data"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end
end

def write_sample_chunk(file_writer, config)
  file_writer.write_or_skip(config["chunk_id"], FOUR_CC)
  file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["manufacturer_id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["product_id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["sample_nanoseconds"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["unity_note"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["pitch_fraction"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["smpte_format"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["smpte_offset"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["loop_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  file_writer.write_or_skip(config["sampler_data_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)

  if config["loops"]
    config["loops"].each do |loop|
      file_writer.write_or_skip(loop["id"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_skip(loop["type"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_skip(loop["start_sample_frame"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_skip(loop["end_sample_frame"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_skip(loop["fraction"], UNSIGNED_INT_32_LITTLE_ENDIAN)
      file_writer.write_or_skip(loop["play_count"], UNSIGNED_INT_32_LITTLE_ENDIAN)
    end
  end

  if config["sampler_data"]
    config["sampler_data"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end

  if config["extra_bytes"]
    config["extra_bytes"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end
end

def write_data_chunk(file_writer, config, format_chunk)
  if format_chunk["audio_format"] == 1
    sample_format = :pcm
  elsif format_chunk["audio_format"] == 3
    sample_format = :float
  elsif format_chunk["audio_format"] == 65534
    if format_chunk["subformat_guid"] == nil
      sample_format = :pcm
    elsif format_chunk["subformat_guid"][0] == 1
      sample_format = :pcm
    elsif format_chunk["subformat_guid"][0] == 3
      sample_format = :float
    end
  end

  file_writer.write_or_skip("data", FOUR_CC)
  if config["chunk_size"]
    file_writer.write_or_skip(config["chunk_size"], UNSIGNED_INT_32_LITTLE_ENDIAN)
  elsif config["cycle_repeats"]
    file_writer.write_or_skip((TOTAL_SAMPLE_FRAMES * format_chunk["block_align"]), UNSIGNED_INT_32_LITTLE_ENDIAN)
  end

  write_square_wave_samples(file_writer, sample_format, format_chunk["bits_per_sample"], format_chunk["channels"])

  if config["extra_data"]
    config["extra_data"].each do |byte|
      file_writer.write_or_skip(byte, UNSIGNED_INT_8)
    end
  end
end

def write_square_wave_samples(file_writer, sample_format, bits_per_sample, channel_count)
  if sample_format == :pcm
    if bits_per_sample == 8
      low_val, high_val, pack_template = 88, 167, UNSIGNED_INT_8
    elsif bits_per_sample == 16
      low_val, high_val, pack_template = -10000, 10000, SIGNED_INT_16_LITTLE_ENDIAN
    elsif bits_per_sample == 24
      low_val, high_val, pack_template = -1_000_000, 1_000_000, SIGNED_INT_24_LITTLE_ENDIAN
    elsif bits_per_sample == 32
      low_val, high_val, pack_template = -1_000_000_000, 1_000_000_000, SIGNED_INT_32_LITTLE_ENDIAN
    end
  elsif sample_format == :float
    if bits_per_sample == 32
      low_val, high_val, pack_template = -0.5, 0.5, FLOAT_32_LITTLE_ENDIAN
    elsif bits_per_sample == 64
      low_val, high_val, pack_template = -0.5, 0.5, FLOAT_64_LITTLE_ENDIAN
    end
  end

  SQUARE_WAVE_CYCLE_REPEATS.times do
    channel_count.times do
      file_writer.write_value(low_val,  pack_template)
      file_writer.write_value(low_val,  pack_template)
      file_writer.write_value(low_val,  pack_template)
      file_writer.write_value(low_val,  pack_template)
    end
    channel_count.times do
      file_writer.write_value(high_val, pack_template)
      file_writer.write_value(high_val, pack_template)
      file_writer.write_value(high_val, pack_template)
      file_writer.write_value(high_val, pack_template)
    end
  end
end

def next_even(number)
  number.even? ? number : (number + 1)
end


yaml_file_name = ARGV[0]
output_file_name = ARGV[1]

chunks = YAML::load(File.read(yaml_file_name))

riff_chunk = chunks["riff_chunk"]
format_chunk = chunks["format_chunk"]
fact_chunk = chunks["fact_chunk"]
junk_chunk = chunks["junk_chunk"]
sample_chunk = chunks["sample_chunk"]
data_chunk = chunks["data_chunk"]
SQUARE_WAVE_CYCLE_REPEATS = (data_chunk && data_chunk["cycle_repeats"]) || 0
TOTAL_SAMPLE_FRAMES = SQUARE_WAVE_CYCLE_SAMPLE_FRAMES * SQUARE_WAVE_CYCLE_REPEATS

if riff_chunk["chunk_size"] == "auto"
  format_chunk_size = format_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES
  fact_chunk_size = fact_chunk ? fact_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES : 0
  junk_chunk_size = junk_chunk ? junk_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES : 0
  sample_chunk_size = sample_chunk ? sample_chunk["chunk_size"] + CHUNK_HEADER_SIZE_IN_BYTES : 0
  data_chunk_size = (data_chunk && data_chunk["chunk_size"]) ? data_chunk["chunk_size"] : (TOTAL_SAMPLE_FRAMES * format_chunk["block_align"])
  riff_chunk["chunk_size"] = RIFF_CHUNK_HEADER_SIZE +
                             next_even(format_chunk_size) +
                             next_even(fact_chunk_size) +
                             next_even(junk_chunk_size) +
                             next_even(sample_chunk_size) +
                             next_even(data_chunk_size)
end

file_writer = FileWriter.new(output_file_name)

chunks.keys.each do |chunk_key|
  case chunk_key
  when "riff_chunk"
    write_riff_chunk(file_writer, riff_chunk)
  when "format_chunk"
    write_format_chunk(file_writer, format_chunk)
  when "fact_chunk"
    write_fact_chunk(file_writer, fact_chunk)
  when "junk_chunk"
    write_junk_chunk(file_writer, junk_chunk)
  when "sample_chunk"
    write_sample_chunk(file_writer, sample_chunk)
  when "data_chunk"
    write_data_chunk(file_writer, data_chunk, format_chunk)
  else
    raise "Unknown chunk key `#{chunk_key}` in `#{yaml_file_name}`, exiting"
  end
end

file_writer.close

FILE = File.open(ARGV[0], "rb")

UNSIGNED_INT_8  = "C"
SIGNED_INT_8 = "c"
UNSIGNED_INT_16 = "v"
UNSIGNED_INT_32 = "V"
FLOAT_32 = "e"

CHUNK_BODY_READERS = {
  "RIFF" => :read_riff_chunk_header,
  "fmt " => :read_format_chunk,
  "fact" => :read_fact_chunk,
  "PEAK" => :read_peak_chunk,
  "cue " => :read_cue_chunk,
  "smpl" => :read_sample_chunk,
  "inst" => :read_instrument_chunk,
  "LIST" => :read_list_chunk,
  "data" => :read_data_chunk,
}
CHUNK_BODY_READERS.default = :read_unrecognized_chunk

def main
  begin
    puts ""

    while true
      chunk_id_data = read_bytes("a4")
      chunk_size_data = read_bytes(UNSIGNED_INT_32)

      display_chunk_header(chunk_id_data, chunk_size_data)

      send(CHUNK_BODY_READERS[chunk_id_data[:parsed_value]], chunk_size_data[:parsed_value])

      # Read padding byte if necessary
      if chunk_size_data[:parsed_value].odd? && chunk_id_data[:parsed_value] != "RIFF"
        display_line("Padding Byte", "byte", read_bytes(UNSIGNED_INT_8))
      end

      puts ""
      puts ""
    end
  rescue EOFError
    FILE.close
  end
end


def read_bytes(pack_str)
  bytes = []
  parsed_value = nil

  if pack_str.start_with?("a")
    if pack_str.length > 1
      size = pack_str[1...(pack_str.length)].to_i
    else
      size = 1
    end

    size.times { bytes << FILE.sysread(1) }
    parsed_value = bytes.join
  elsif pack_str == UNSIGNED_INT_32
    4.times { bytes << FILE.sysread(1) }
    parsed_value = bytes.join.unpack(UNSIGNED_INT_32).first
  elsif pack_str == UNSIGNED_INT_16
    2.times { bytes << FILE.sysread(1) }
    parsed_value = bytes.join.unpack(UNSIGNED_INT_16).first
  elsif pack_str == UNSIGNED_INT_8
    bytes << FILE.sysread(1)
    parsed_value = bytes.join.unpack(UNSIGNED_INT_8).first
  elsif pack_str.start_with?(UNSIGNED_INT_8)
    size = pack_str[1...(pack_str.length)].to_i

    size.times { bytes << FILE.sysread(1) }
    parsed_value = "N/A"
  elsif pack_str == SIGNED_INT_8
    bytes << FILE.sysread(1)
    parsed_value = bytes.join.unpack(SIGNED_INT_8).first
  elsif pack_str == FLOAT_32
    4.times { bytes << FILE.sysread(1) }
    parsed_value = bytes.join.unpack(FLOAT_32).first
  elsif pack_str.start_with?("H")
    if pack_str.length > 2
      size = pack_str[1...(pack_str.length)].to_i / 2
    else
      size = 1
    end

    size.times { bytes << FILE.sysread(1) }
    parsed_value = "0x#{bytes.map {|byte| byte.unpack("H2")}.join}"
  elsif pack_str.start_with?("B")
    if pack_str.length > 1
      size = pack_str[1...(pack_str.length)].to_i
    else
      size = 1
    end
    size /= 8

    size.times { bytes << FILE.sysread(1) }
    parsed_value = bytes.reverse.map {|byte| byte.unpack("B8")}.join
  else
    raise "Unhandled pack string \"#{pack_str}\""
  end

  return { parsed_value: parsed_value, bytes: bytes }
end


def display_line(label, data_type, h)
  parsed_value = h[:parsed_value]
  bytes = h[:bytes]

  if data_type == "FourCC" || data_type.start_with?("alpha")
    # Wrap the value in quotes and show character codes for non-display characters
    formatted_value = parsed_value.inspect
  else
    # This branch exists to avoid wrapping a value in quotes when it semantically
    # is not a String but happens to be contained in a String object (e.g. a bit field,
    # GUID, etc).
    formatted_value = parsed_value.to_s
  end

  formatted_bytes = bytes.map {|byte| byte.unpack("H2").first }.join(" ")

  puts "#{(label + ":").ljust(22)} #{data_type.ljust(10)} | #{formatted_value.ljust(10)} | #{formatted_bytes}"
end


def display_chunk_header(chunk_id, chunk_size)
  title = "#{chunk_id[:parsed_value].inspect} Chunk"

  if chunk_id[:parsed_value] == "RIFF"
    title += " Header"
  elsif CHUNK_BODY_READERS.keys.member?(chunk_id[:parsed_value]) == false
    title += " (unrecognized chunk type)"
  end

  puts title
  puts "=================================================================================="
  display_line("Chunk ID", "FourCC", chunk_id)
  display_line("Chunk size", "uint_32", chunk_size)
  display_chunk_section_separator
end


def display_chunk_section_separator
  puts "----------------------------------+------------+----------------------------------"
end


def read_riff_chunk_header(chunk_size)
  display_line("Form type", "FourCC", read_bytes("a4"))
end


def read_format_chunk(chunk_size)
  audio_format_code = read_bytes(UNSIGNED_INT_16)
  display_line("Audio format",    "uint_16", audio_format_code)
  display_line("Channels",        "uint_16", read_bytes(UNSIGNED_INT_16))
  display_line("Sample rate",     "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("Byte rate",       "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("Block align",     "uint_16", read_bytes(UNSIGNED_INT_16))
  display_line("Bits per sample", "uint_16", read_bytes(UNSIGNED_INT_16))

  bytes_read_so_far = 16

  if audio_format_code[:parsed_value] != 1 && chunk_size > 16
    extension_size_data = read_bytes(UNSIGNED_INT_16)
    display_line("Extension size", "uint_16", extension_size_data)
    bytes_read_so_far += 2

    if extension_size_data[:parsed_value] > 0
      if audio_format_code[:parsed_value] == 65534
        display_line("Valid bits per sample", "uint_16", read_bytes(UNSIGNED_INT_16))
        display_line("Speaker mapping", "Bit field", read_bytes("B32"))
        display_line("Sub format GUID", "GUID", read_bytes("H32"))

        extra_byte_count = extension_size_data[:parsed_value] - 22
        if extra_byte_count > 0
          display_line("Extra extension bytes", "bytes", read_bytes("#{UNSIGNED_INT_8}#{extra_byte_count}"))
        end
      else
        extension_pack_code = "#{UNSIGNED_INT_8}#{extension_size_data[:parsed_value]}"
        display_line("Raw extension", "bytes", read_bytes(extension_pack_code))
      end
    end

    bytes_read_so_far += extension_size_data[:parsed_value]
  end

  extra_byte_count = chunk_size - bytes_read_so_far
  if extra_byte_count > 0
    display_line("Extra bytes", "bytes", read_bytes("#{UNSIGNED_INT_8}#{extra_byte_count}"))
  end
end


def read_fact_chunk(chunk_size)
  display_line("Sample count", "uint_32", read_bytes(UNSIGNED_INT_32))

  if chunk_size > 4
    FILE.sysread(chunk_size - 4)
  end
end


def read_peak_chunk(chunk_size)
  display_line("Version",          "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("Timestamp",        "uint_32", read_bytes(UNSIGNED_INT_32))

  ((chunk_size - 8) / 8).times do |i|
    display_line("Chan. #{i + 1} Value",    "float_32", read_bytes(FLOAT_32))
    display_line("Chan. #{i + 1} Position", "uint_32", read_bytes(UNSIGNED_INT_32))
  end
end


def read_cue_chunk(chunk_size)
  display_line("Cue point count", "uint_32", read_bytes(UNSIGNED_INT_32))

  ((chunk_size - 4) / 24).times do |i|
    display_line("ID #{i + 1}", "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Position #{i + 1}", "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Chunk type #{i + 1}", "FourCC", read_bytes("a4"))
    display_line("Chunk start #{i + 1}", "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Block start #{i + 1}", "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Sample offset #{i + 1}", "uint_32", read_bytes(UNSIGNED_INT_32))
  end
end


def read_sample_chunk(chunk_size)
  display_line("Manufacturer",        "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("Product",             "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("Sample Period",       "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("MIDI Unity Note",     "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("MIDI Pitch Fraction", "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("SMPTEFormat",         "uint_32", read_bytes(UNSIGNED_INT_32))
  display_line("SMPTEOffset",         "uint_32", read_bytes(UNSIGNED_INT_32))

  sample_loops_bytes = read_bytes(UNSIGNED_INT_32)
  loop_count = sample_loops_bytes[:parsed_value]
  display_line("Sample Loops",        "uint_32", sample_loops_bytes)

  sampler_specific_data_size_bytes = read_bytes(UNSIGNED_INT_32)
  sampler_specific_data_size = sampler_specific_data_size_bytes[:parsed_value]
  display_line("Sampler Data Size",   "uint_32", sampler_specific_data_size_bytes)

  loop_count.times do |i|
    display_chunk_section_separator
    puts "Loop ##{i + 1}:"
    display_line("Identifier", "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Type",       "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Start",      "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("End",        "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Fraction",   "uint_32", read_bytes(UNSIGNED_INT_32))
    display_line("Play Count", "uint_32", read_bytes(UNSIGNED_INT_32))
  end

  if sampler_specific_data_size > 0
    display_chunk_section_separator
    display_line("Sampler specific data", "bytes", read_bytes("#{UNSIGNED_INT_8}#{sampler_specific_data_size}"))
  end

  extra_byte_count = chunk_size - 36 - (loop_count * 24) - sampler_specific_data_size_bytes[:parsed_value]
  if (extra_byte_count > 0)
    display_line("Extra bytes", "bytes", read_bytes("#{UNSIGNED_INT_8}#{extra_byte_count}"))
  end
end


def read_instrument_chunk(chunk_size)
  display_line("Unshifted Note", "uint_8", read_bytes(UNSIGNED_INT_8))
  display_line("Fine Tune",      "int_8", read_bytes(SIGNED_INT_8))
  display_line("Gain",           "int_8", read_bytes(SIGNED_INT_8))
  display_line("Low Note",       "uint_8", read_bytes(UNSIGNED_INT_8))
  display_line("High Note",      "uint_8", read_bytes(UNSIGNED_INT_8))
  display_line("Low Velocity",   "uint_8", read_bytes(UNSIGNED_INT_8))
  display_line("High Velocity",  "uint_8", read_bytes(UNSIGNED_INT_8))

  extra_data_size = chunk_size - 7
  if extra_data_size > 0
    display_line("Extra Data", "bytes", read_bytes("#{UNSIGNED_INT_8}#{extra_data_size}"))
  end
end


def read_list_chunk(chunk_size)
  list_type = read_bytes("a4")
  display_line("List Type", "FourCC", list_type)

  bytes_remaining = chunk_size - 4

  while bytes_remaining > 1
    display_chunk_section_separator
    display_line("Sub Type ID", "FourCC", read_bytes("a4"))

    size_bytes = read_bytes(UNSIGNED_INT_32)
    size = size_bytes[:parsed_value]

    display_line("Size", "uint_32", size_bytes)

    if list_type[:parsed_value] == "adtl"
      display_line("Cue Point ID", "uint_32", read_bytes(UNSIGNED_INT_32))
      display_line("Content", "alpha_#{size - 4}", read_bytes("a#{size - 4}"))

      bytes_remaining -= (size + 8)
    else   # INFO, and any unknown list type
      display_line("Content", "alpha_#{size}", read_bytes("a#{size}"))

      bytes_remaining -= (size + 8)
    end
  end

  FILE.sysread(bytes_remaining)
end


def read_data_chunk(chunk_size)
  intro_byte_count = [10, chunk_size].min

  if intro_byte_count > 0
    display_line("Data Start", "bytes", read_bytes("#{UNSIGNED_INT_8}#{intro_byte_count}"))
  end

  FILE.sysread(chunk_size - intro_byte_count)
end


def read_unrecognized_chunk(chunk_size)
  if chunk_size > 0
    puts "(chunk body omitted)"
  end
  FILE.sysread(chunk_size)
end


main

FILE = File.open(ARGV[0], "rb")

UNSIGNED_INT_8  = "C"
SIGNED_INT_8 = "c"
UNSIGNED_INT_16 = "v"
UNSIGNED_INT_32 = "V"

def main
  begin
    # RIFF header
    puts ""
    display_chunk_header("Riff Chunk Header", read_bytes("a4"), read_bytes(UNSIGNED_INT_32))
    display_line "Form type", "FourCC", read_bytes("a4")
    puts ""
    puts ""

    while true
      chunk_id_data = read_bytes("a4")
      chunk_size_data = read_bytes(UNSIGNED_INT_32)

      case chunk_id_data[:actual]
        when "fmt " then
          read_format_chunk(chunk_id_data, chunk_size_data)
        when "fact" then
          read_fact_chunk(chunk_id_data, chunk_size_data)
        when "PEAK" then
          read_peak_chunk(chunk_id_data, chunk_size_data)
        when "cue " then
          read_cue_chunk(chunk_id_data, chunk_size_data)
        when "smpl" then
          read_sample_chunk(chunk_id_data, chunk_size_data)
        when "inst" then
          read_instrument_chunk(chunk_id_data, chunk_size_data)
        when "LIST" then
          read_list_chunk(chunk_id_data, chunk_size_data)
        when "data" then
          read_data_chunk(chunk_id_data, chunk_size_data)
        else
          chunk_size = chunk_size_data[:actual]

          puts "'#{chunk_id_data[:actual]}' chunk of size #{chunk_size}, skipping."
          FILE.sysread(chunk_size)
      end

      # Read padding byte if necessary
      if chunk_size_data[:actual].odd?
        display_line "Padding Byte", "byte", read_bytes(UNSIGNED_INT_8)
      end

      puts ""
      puts ""
    end
  rescue EOFError
    FILE.close()
  end
end


def read_bytes(pack_str)
  bytes = []

  if pack_str.start_with?("a")
    if pack_str.length > 1
      size = pack_str[1...(pack_str.length)].to_i
    else
      size = 1
    end

    size.times { bytes << FILE.sysread(1).unpack("a") }
    full_string = bytes.join()

    return {actual: full_string, bytes: bytes }
  elsif pack_str == UNSIGNED_INT_32
    4.times { bytes << FILE.sysread(1) }
    val = bytes.join().unpack(UNSIGNED_INT_32).first

    return {actual: val, bytes: bytes }
  elsif pack_str == UNSIGNED_INT_16
    2.times { bytes << FILE.sysread(1) }
    val = bytes.join().unpack(UNSIGNED_INT_16).first

    return {actual: val, bytes: bytes }
  elsif pack_str == UNSIGNED_INT_8
    bytes << FILE.sysread(1)
    val = bytes.join().unpack(UNSIGNED_INT_8).first

    return {actual: val, bytes: bytes }
  elsif pack_str == SIGNED_INT_8
    bytes << FILE.sysread(1)
    val = bytes.join().unpack(SIGNED_INT_8).first

    return {actual: val, bytes: bytes }
  elsif pack_str.start_with?("H")
    if pack_str.length > 2
      size = pack_str[1...(pack_str.length)].to_i / 2
    else
      size = 1
    end

    size.times { bytes << FILE.sysread(1).unpack("H2") }
    full_string = "0x#{bytes.join()}"

    return {actual: full_string, bytes: bytes }
  elsif pack_str.start_with?("B")
    if pack_str.length > 1
      size = pack_str[1...(pack_str.length)].to_i
    else
      size = 1
    end
    size /= 8

    size.times { bytes << FILE.sysread(1).unpack("B8") }
    full_string = bytes.reverse.join()

    return {actual: full_string, bytes: bytes }
  end
end


def display_line(label, expected, h)
  actual = h[:actual]
  bytes = h[:bytes]

  if Integer === actual
    formatted_bytes = bytes.map {|byte| "#{byte.unpack(UNSIGNED_INT_8)}" }.join(" ")
  elsif String === actual
    formatted_bytes = bytes.inspect.gsub('[[', '[').gsub(']]', ']').gsub(',', '')
  else
    formatted_bytes = bytes
  end

  puts "#{(label + ":").ljust(22)} #{expected.ljust(10)} | #{actual.to_s.ljust(10).gsub("\n\n", "")} | #{formatted_bytes}"
end


def display_chunk_header(heading, chunk_id, chunk_size)
  puts heading
  puts "=================================================================================="
  display_line "Chunk ID", "FourCC", chunk_id
  display_line "Chunk size", "int_32", chunk_size
  display_chunk_section_separator
end


def display_chunk_section_separator
  puts "----------------------------------+------------+----------------------------------"
end


def read_format_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Format Chunk", chunk_id_data, chunk_size_data)
  audio_format_code = read_bytes(UNSIGNED_INT_16)
  display_line "Audio format",    "int_16", audio_format_code
  display_line "Channels",        "int_16", read_bytes(UNSIGNED_INT_16)
  display_line "Sample rate",     "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "Byte rate",       "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "Block align",     "int_16", read_bytes(UNSIGNED_INT_16)
  display_line "Bits per sample", "int_16", read_bytes(UNSIGNED_INT_16)

  bytes_read_so_far = 16

  if audio_format_code[:actual] != 1 && chunk_size_data[:actual] > 16
    extension_size_data = read_bytes(UNSIGNED_INT_16)
    display_line "Extension size", "int_16", extension_size_data
    bytes_read_so_far += 2

    if extension_size_data[:actual] > 0
      if audio_format_code[:actual] == 65534
        display_line "Valid bits per sample", "int_16", read_bytes(UNSIGNED_INT_16)
        display_line "Speaker mapping", "binary", read_bytes("B32")
        display_line "Sub format GUID", "hex", read_bytes("H32")

        extra_byte_count = extension_size_data[:actual] - 22
        if extra_byte_count > 0
          display_line "Extra extension bytes", "alpha_#{extra_byte_count}", read_bytes("a#{extra_byte_count}")
        end
      else
        extension_pack_code = "a#{extension_size_data[:actual]}"
        display_line "Raw extension", "alpha_#{extension_size_data[:actual]}", read_bytes(extension_pack_code)
      end
    end

    bytes_read_so_far += extension_size_data[:actual]
  end

  extra_byte_count = chunk_size_data[:actual] - bytes_read_so_far
  if extra_byte_count > 0
    display_line "Extra bytes", "alpha_#{extra_byte_count}", read_bytes("a#{extra_byte_count}")
  end
end


def read_fact_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Fact Chunk", chunk_id_data, chunk_size_data)
  display_line "Sample count", "int_32", read_bytes(UNSIGNED_INT_32)

  if chunk_size_data[:actual] > 4
    FILE.sysread(chunk_size_data[:actual] - 4)
  end
end


def read_peak_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Peak Chunk", chunk_id_data, chunk_size_data)

  display_line "Version",          "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "Timestamp",        "int_32", read_bytes(UNSIGNED_INT_32)

  ((chunk_size_data[:actual] - 8) / 8).times do |i|
    # TODO: Fix this to be a 4 byte signed float
    display_line "Chan. #{i + 1} Value",    "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Chan. #{i + 1} Position", "int_32", read_bytes(UNSIGNED_INT_32)
  end
end


def read_cue_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Cue Chunk", chunk_id_data, chunk_size_data)

  display_line "Cue point count", "int_32", read_bytes(UNSIGNED_INT_32)

  ((chunk_size_data[:actual] - 4) / 24).times do |i|
    display_line "ID #{i + 1}", "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Position #{i + 1}", "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Chunk type #{i + 1}", "FourCC", read_bytes("a4")
    display_line "Chunk start #{i + 1}", "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Block start #{i + 1}", "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Sample offset #{i + 1}", "int_32", read_bytes(UNSIGNED_INT_32)
  end
end


def read_sample_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Sample Chunk", chunk_id_data, chunk_size_data)

  display_line "Manufacturer",        "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "Product",             "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "Sample Period",       "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "MIDI Unity Note",     "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "MIDI Pitch Fraction", "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "SMPTEFormat",         "int_32", read_bytes(UNSIGNED_INT_32)
  display_line "SMPTEOffset",         "int_32", read_bytes(UNSIGNED_INT_32)

  sample_loops_bytes = read_bytes(UNSIGNED_INT_32)
  loop_count = sample_loops_bytes[:actual]
  display_line "Sample Loops",        "int_32", sample_loops_bytes

  sampler_specific_data_size_bytes = read_bytes(UNSIGNED_INT_32)
  sampler_specific_data_size = sampler_specific_data_size_bytes[:actual]
  display_line "Sampler Data Size",   "int_32", sampler_specific_data_size_bytes

  loop_count.times do |i|
    display_chunk_section_separator
    puts "Loop ##{i + 1}:"
    display_line "Identifier", "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Type",       "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Start",      "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "End",        "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Fraction",   "int_32", read_bytes(UNSIGNED_INT_32)
    display_line "Play Count", "int_32", read_bytes(UNSIGNED_INT_32)
  end

  if sampler_specific_data_size > 0
    display_chunk_section_separator
    display_line "Sampler specific data", "alpha_#{sampler_specific_data_size}", read_bytes("a#{sampler_specific_data_size}")
  end

  extra_byte_count = chunk_size_data[:actual] - 36 - (loop_count * 24) - sampler_specific_data_size_bytes[:actual]
  if (extra_byte_count > 0)
    display_line "Extra bytes", "alpha_#{extra_byte_count}", read_bytes("a#{extra_byte_count}")
  end
end


def read_instrument_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("Instrument Chunk", chunk_id_data, chunk_size_data)

  display_line "Unshifted Note", "byte", read_bytes(UNSIGNED_INT_8)
  display_line "Fine Tune",      "byte", read_bytes(SIGNED_INT_8)
  display_line "Gain",           "byte", read_bytes(SIGNED_INT_8)
  display_line "Low Note",       "byte", read_bytes(UNSIGNED_INT_8)
  display_line "High Note",      "byte", read_bytes(UNSIGNED_INT_8)
  display_line "Low Velocity",   "byte", read_bytes(UNSIGNED_INT_8)
  display_line "High Velocity",  "byte", read_bytes(UNSIGNED_INT_8)

  extra_data_size = chunk_size_data[:actual] - 7
  if extra_data_size > 0
    display_line "Extra Data", "alpha_#{extra_data_size}", read_bytes("a#{extra_data_size}")
  end
end


def read_list_chunk(chunk_id_data, chunk_size_data)
  display_chunk_header("List Chunk", chunk_id_data, chunk_size_data)

  list_type = read_bytes("a4")
  display_line "List Type", "FourCC", list_type

  bytes_remaining = chunk_size_data[:actual] - 4

  while bytes_remaining > 1
    display_chunk_section_separator
    display_line "Sub Type ID", "FourCC", read_bytes("a4")

    size_bytes = read_bytes(UNSIGNED_INT_32)
    size = size_bytes[:actual]

    display_line "Size", "int_32", size_bytes

    if list_type[:actual] == "adtl"
      display_line "Cue Point ID", "int_32", read_bytes(UNSIGNED_INT_32)
      display_line "Content", "alpha_#{size - 4}", read_bytes("a#{size - 4}")

      bytes_remaining -= (size + 8)
    else   # INFO, and any unknown list type
      display_line "Content", "alpha_#{size}", read_bytes("a#{size}")

      bytes_remaining -= (size + 8)
    end
  end

  FILE.sysread(bytes_remaining)
end


def read_data_chunk(chunk_id_data, chunk_size_data)
  intro_byte_count = [10, chunk_size_data[:actual]].min

  display_chunk_header("Data Chunk", chunk_id_data, chunk_size_data)

  if intro_byte_count > 0
    display_line "Data Start", "alpha_#{intro_byte_count}", read_bytes("a#{intro_byte_count}")
  end

  FILE.sysread(chunk_size_data[:actual] - intro_byte_count)
end


main

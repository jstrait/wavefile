CHUNK_BODY_READERS = {
  "RIFF" => :read_riff_chunk,
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
  File.open(ARGV[0], "rb") do |file|
    field_reader = FieldReader.new(file)

    begin
      begin
        riff_chunk_id_field = field_reader.read_fourcc
        riff_chunk_size_field = field_reader.read_uint32
      ensure
        if riff_chunk_id_field != nil
          display_chunk_header(riff_chunk_id_field, riff_chunk_size_field)
        end
      end

      read_riff_chunk(field_reader, riff_chunk_size_field[:parsed_value])
    rescue EOFError
      # Swallow the error and do nothing to avoid an error being shown in the output.
      # Perhaps in the future it would be better to show an indication that the end
      # of the file was unexpectedly reached.
    end
  end
end


def read_riff_chunk(field_reader, chunk_size)
  display_field("Form Type", field_reader.read_fourcc)

  while field_reader.bytes_read < chunk_size + 8
    child_chunk_id_field, child_chunk_size_field = nil

    begin
      child_chunk_id_field = field_reader.read_fourcc
      child_chunk_size_field = field_reader.read_uint32
    ensure
      if child_chunk_id_field != nil
        puts ""
        puts ""

        display_chunk_header(child_chunk_id_field, child_chunk_size_field)
      end
    end

    chunk_body_reader_method_name = CHUNK_BODY_READERS[child_chunk_id_field[:parsed_value]]
    send(chunk_body_reader_method_name, field_reader, child_chunk_size_field[:parsed_value])

    if child_chunk_size_field[:parsed_value].odd?
      display_field("Padding Byte", field_reader.read_padding_byte)
    end
  end
end


def read_format_chunk(field_reader, chunk_size)
  format_tag_field = field_reader.read_uint16
  display_field("Format Tag", format_tag_field)
  display_field("Channel Count", field_reader.read_uint16)
  display_field("Sample Rate", field_reader.read_uint32)
  display_field("Avg. Bytes Per Second", field_reader.read_uint32)
  display_field("Block Align", field_reader.read_uint16)
  display_field("Bits Per Sample", field_reader.read_uint16)

  bytes_read_so_far = 16

  if format_tag_field[:parsed_value] != 1 && chunk_size > 16
    extension_size_field = field_reader.read_uint16
    display_chunk_section_separator
    display_field("Extension Size", extension_size_field)
    bytes_read_so_far += 2

    if extension_size_field[:parsed_value] > 0
      if format_tag_field[:parsed_value] == 65534
        display_field("Valid Bits Per Sample", field_reader.read_uint16)
        display_field("Speaker Mapping", field_reader.read_bitfield(4))
        display_field("Sub Format GUID", field_reader.read_guid)

        extra_byte_count = extension_size_field[:parsed_value] - 22
        if extra_byte_count > 0
          display_field("Extra Extension Bytes", field_reader.read_bytes(extra_byte_count))
        end
      else
        display_field("Raw Extension", field_reader.read_bytes(extension_size_field[:parsed_value]))
      end
    end

    bytes_read_so_far += extension_size_field[:parsed_value]
  end

  extra_byte_count = chunk_size - bytes_read_so_far
  if extra_byte_count > 0
    display_chunk_section_separator
    display_field("Extra Bytes", field_reader.read_bytes(extra_byte_count))
  end
end


def read_fact_chunk(field_reader, chunk_size)
  display_field("Sample Count", field_reader.read_uint32)

  if chunk_size > 4
    display_chunk_section_separator
    display_field("Extra Bytes", field_reader.read_bytes(chunk_size - 4))
  end
end


def read_peak_chunk(field_reader, chunk_size)
  display_field("Version", field_reader.read_uint32)
  display_field("Timestamp", field_reader.read_uint32)

  ((chunk_size - 8) / 8).times do |i|
    display_field("Chan. #{i + 1} Value", field_reader.read_float32)
    display_field("Chan. #{i + 1} Position", field_reader.read_uint32)
  end
end


def read_cue_chunk(field_reader, chunk_size)
  cue_point_count_field = field_reader.read_uint32
  display_field("Cue Point Count", cue_point_count_field)

  bytes_remaining = chunk_size - 4

  cue_point_count_field[:parsed_value].times do |i|
    display_chunk_section_separator
    display_field("ID #{i + 1}", field_reader.read_uint32)
    display_field("Position #{i + 1}", field_reader.read_uint32)
    display_field("Chunk Type #{i + 1}", field_reader.read_fourcc)
    display_field("Chunk Start #{i + 1}", field_reader.read_uint32)
    display_field("Block Start #{i + 1}", field_reader.read_uint32)
    display_field("Sample Offset #{i + 1}", field_reader.read_uint32)
    bytes_remaining -= 24
  end

  if bytes_remaining > 0
    display_chunk_section_separator
    display_field("Extra Bytes", field_reader.read_bytes(bytes_remaining))
  end
end


def read_sample_chunk(field_reader, chunk_size)
  display_field("Manufacturer", field_reader.read_uint32)
  display_field("Product", field_reader.read_uint32)
  display_field("Sample Period", field_reader.read_uint32)
  display_field("MIDI Unity Note", field_reader.read_uint32)
  display_field("MIDI Pitch Fraction", field_reader.read_uint32)
  display_field("SMPTE Format", field_reader.read_uint32)
  display_field("SMPTE Offset", field_reader.read_uint32)

  loop_count_field = field_reader.read_uint32
  loop_count = loop_count_field[:parsed_value]
  display_field("Sample Loop Count", loop_count_field)

  sampler_specific_data_size_field = field_reader.read_uint32
  sampler_specific_data_size = sampler_specific_data_size_field[:parsed_value]
  display_field("Sampler Data Size", sampler_specific_data_size_field)

  loop_count.times do |i|
    display_chunk_section_separator
    puts "Loop ##{i + 1}:"
    display_field("Identifier", field_reader.read_uint32)
    display_field("Type", field_reader.read_uint32)
    display_field("Start Sample Frame", field_reader.read_uint32)
    display_field("End Sample Frame", field_reader.read_uint32)
    display_field("Fraction", field_reader.read_uint32)
    display_field("Play Count", field_reader.read_uint32)
  end

  if sampler_specific_data_size > 0
    display_chunk_section_separator
    display_field("Sampler Specific Data", field_reader.read_bytes(sampler_specific_data_size))
  end

  extra_byte_count = chunk_size - 36 - (loop_count * 24) - sampler_specific_data_size_field[:parsed_value]
  if (extra_byte_count > 0)
    display_chunk_section_separator
    display_field("Extra Bytes", field_reader.read_bytes(extra_byte_count))
  end
end


def read_instrument_chunk(field_reader, chunk_size)
  display_field("Unshifted Note", field_reader.read_uint8)
  display_field("Fine Tune", field_reader.read_int8)
  display_field("Gain", field_reader.read_int8)
  display_field("Low Note", field_reader.read_uint8)
  display_field("High Note", field_reader.read_uint8)
  display_field("Low Velocity", field_reader.read_uint8)
  display_field("High Velocity", field_reader.read_uint8)

  extra_data_size = chunk_size - 7
  if extra_data_size > 0
    display_chunk_section_separator
    display_field("Extra Bytes", field_reader.read_bytes(extra_data_size))
  end
end


def read_list_chunk(field_reader, chunk_size)
  list_type_field = field_reader.read_fourcc
  display_field("List Type", list_type_field)

  bytes_remaining = chunk_size - 4

  while bytes_remaining > 0
    display_chunk_section_separator
    child_chunk_id_field = field_reader.read_fourcc
    display_field("Child Chunk ID", child_chunk_id_field)

    child_chunk_size_field = field_reader.read_uint32
    child_chunk_size = child_chunk_size_field[:parsed_value]

    display_field("Child Chunk Size", child_chunk_size_field)

    if list_type_field[:parsed_value] == "adtl"
      display_field("Cue Point ID", field_reader.read_uint32)

      if child_chunk_id_field[:parsed_value] == "ltxt"
        display_field("Sample Length", field_reader.read_uint32)
        display_field("Purpose", field_reader.read_fourcc)
        display_field("Country", field_reader.read_uint16)
        display_field("Language", field_reader.read_uint16)
        display_field("Dialect", field_reader.read_uint16)
        display_field("Code Page", field_reader.read_uint16)

        if child_chunk_size > 20
          display_field("Text", field_reader.read_bytes(child_chunk_size - 20))
        end
      else
        display_field("Content", field_reader.read_null_terminated_string(child_chunk_size - 4))
      end

      bytes_remaining -= (child_chunk_size + 8)
    else   # INFO, and any unknown list type
      display_field("Content", field_reader.read_null_terminated_string(child_chunk_size))

      bytes_remaining -= (child_chunk_size + 8)
    end

    if child_chunk_size.odd?
      display_field("Padding Byte", field_reader.read_padding_byte)
      bytes_remaining -= 1
    end
  end
end


def read_data_chunk(field_reader, chunk_size)
  intro_byte_count = [10, chunk_size].min

  if intro_byte_count > 0
    display_field("First #{intro_byte_count} bytes", field_reader.read_bytes(intro_byte_count))
  end

  if intro_byte_count < chunk_size
    skipped_byte_count = field_reader.skip_bytes(chunk_size - intro_byte_count)
    puts "(remaining #{skipped_byte_count} bytes omitted)"
  end
end


def read_unrecognized_chunk(field_reader, chunk_size)
  if chunk_size > 0
    skipped_byte_count = field_reader.skip_bytes(chunk_size)
    puts "(unrecognized chunk type; #{skipped_byte_count} byte chunk body omitted)"
  end
end


class FieldReader
  def initialize(file)
    @file = file
    @bytes_read = 0
  end

  attr_reader :bytes_read

  def read_int8
    read_field(byte_count: 1,
               type_label: "int8",
               parser: lambda {|bytes| bytes.join.unpack("c").first })
  end

  def read_uint8
    read_field(byte_count: 1,
               type_label: "uint8",
               parser: lambda {|bytes| bytes.join.unpack("C").first })
  end

  def read_uint16
    read_field(byte_count: 2,
               type_label: "uint16",
               parser: lambda {|bytes| bytes.join.unpack("v").first })
  end

  def read_uint32
    read_field(byte_count: 4,
               type_label: "uint32",
               parser: lambda {|bytes| bytes.join.unpack("V").first })
  end

  def read_float32
    read_field(byte_count: 4,
               type_label: "float32",
               parser: lambda {|bytes| bytes.join.unpack("e").first })
  end

  def read_fourcc
    read_field(byte_count: 4,
               type_label: "FourCC",
               parser: lambda {|bytes| bytes.join })
  end

  def read_null_terminated_string(byte_count)
    read_field(byte_count: byte_count,
               type_label: "C String",
               parser: lambda {|bytes| bytes.join.unpack("Z#{byte_count}").first })
  end

  def read_bitfield(byte_count)
    read_field(byte_count: byte_count,
               type_label: "Bit field",
               parser: lambda {|bytes| "0x#{bytes.reverse.map {|byte| byte.unpack("H2")}.join}"})
  end

  def read_guid
    parser_lambda = lambda do |bytes|
      # The first 3 byte groups of the GUID string contain little-endian numbers,
      # while the last 2 contain raw bytes. This is why only the first 3 byte groups
      # have their order reversed.
      byte_groups = [bytes[0..3].reverse, bytes[4..5].reverse, bytes[6..7].reverse, bytes[8..9], bytes[10..15]]

      byte_group_strings = byte_groups.map do |byte_group|
        byte_group.map {|bytes| bytes.unpack("H2")}.join
      end

      byte_group_strings.join("-")
    end

    read_field(byte_count: 16,
               type_label: "GUID",
               parser: parser_lambda)
  end

  def read_bytes(byte_count)
    read_field(byte_count: byte_count,
               type_label: "bytes",
               parser: lambda {|bytes| "N/A" })
  end

  def read_padding_byte
    read_field(byte_count: 1,
               type_label: "byte",
               parser: lambda {|bytes| bytes.join.unpack("C").first })
  end

  def skip_bytes(byte_count)
    string = @file.sysread(byte_count)

    @bytes_read += string.length
    string.length
  end

  private

  def read_field(byte_count: nil, type_label: nil, parser: nil)
    bytes = read_field_bytes(byte_count)

    {
      bytes: bytes,
      type_label: type_label,
      parsed_value: parser.call(bytes)
    }
  end

  def read_field_bytes(byte_count)
    bytes = []

    byte_count.times do |i|
      bytes << @file.sysread(1)
      @bytes_read += 1
    end

    bytes
  end
end


def display_chunk_header(chunk_id_field, chunk_size_field)
  title = "#{chunk_id_field[:parsed_value].inspect} Chunk"

  if chunk_id_field[:parsed_value] == "RIFF"
    title += " Header"
  end

  puts title
  puts "================================================================================"

  display_field("Chunk ID", chunk_id_field)

  if chunk_size_field != nil
    display_field("Chunk Size", chunk_size_field)
    display_chunk_section_separator
  end
end


def display_field(label, field)
  parsed_value = field[:parsed_value]
  bytes = field[:bytes]
  data_type = field[:type_label]

  label_lines = [label + ":"]
  data_type_lines = [data_type]

  if data_type == "FourCC" || data_type == "C String"
    # Wrap the value in quotes and show character codes for non-display characters
    formatted_parsed_value = parsed_value.inspect

    parsed_value_lines = formatted_parsed_value.chars[1..-1].each_slice(18).map {|line| line.join}
    parsed_value_lines.first.prepend("\"")
    parsed_value_lines[1..-1].each {|line| line.prepend(" ")}
  else
    # This branch exists to avoid wrapping a value in quotes when it semantically
    # is not a String but happens to be contained in a String object (e.g. a bit field,
    # GUID, etc).
    formatted_parsed_value = parsed_value.to_s

    parsed_value_lines = formatted_parsed_value.chars.each_slice(19).map {|line| line.join}
  end

  formatted_bytes = bytes.map {|byte| byte.unpack("H2").first }
  bytes_lines = formatted_bytes.each_slice(8).map {|line| line.join(" ")}

  line_count = [parsed_value_lines.length, bytes_lines.length].max

  line_count.times do |i|
    puts "#{(label_lines[i] || "").ljust(22)} "\
         "#{(data_type_lines[i] || "").ljust(9)} | "\
         "#{(parsed_value_lines[i] || "").ljust(19)} | "\
         "#{(bytes_lines[i] || "")}"
  end
end


def display_chunk_section_separator
  puts "---------------------------------+---------------------+------------------------"
end


main

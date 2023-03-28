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
        riff_chunk_id_field = field_reader.read_fourcc("Chunk ID")
        riff_chunk_size_field = field_reader.read_uint32("Chunk Size")
      ensure
        if riff_chunk_id_field != nil
          display_chunk_header(riff_chunk_id_field, riff_chunk_size_field)
        end
      end

      field_reader.with_byte_limit(riff_chunk_size_field.value) do
        read_riff_chunk(field_reader, riff_chunk_size_field.value)
      end
    rescue EOFError
      # Swallow the error and do nothing to avoid an error being shown in the output.
      # Perhaps in the future it would be better to show an indication that the end
      # of the file was unexpectedly reached.
    end
  end
end


def read_riff_chunk(field_reader, chunk_size)
  display_field(field_reader.read_fourcc("Form Type"))

  while field_reader.remaining_byte_limit > 0
    child_chunk_id_field, child_chunk_size_field = nil

    begin
      child_chunk_id_field = field_reader.read_fourcc("Chunk ID")
      child_chunk_size_field = field_reader.read_uint32("Chunk Size")
    ensure
      if child_chunk_id_field != nil
        puts ""
        puts ""

        display_chunk_header(child_chunk_id_field, child_chunk_size_field)
      end
    end

    return if child_chunk_size_field.value.nil?

    chunk_body_reader_method_name = CHUNK_BODY_READERS[child_chunk_id_field.value]
    field_reader.with_byte_limit(child_chunk_size_field.value) do
      send(chunk_body_reader_method_name, field_reader, child_chunk_size_field.value)
    end

    if child_chunk_size_field.value.odd?
      display_field(field_reader.read_padding_byte("Padding Byte"))
    end
  end
end


def read_format_chunk(field_reader, chunk_size)
  format_tag_field = field_reader.read_uint16("Format Tag")
  format_tag = format_tag_field.value

  display_field(format_tag_field)
  display_field(field_reader.read_uint16("Channel Count"))
  display_field(field_reader.read_uint32("Sample Rate"))
  display_field(field_reader.read_uint32("Avg. Bytes Per Second"))
  display_field(field_reader.read_uint16("Block Align"))
  display_field(field_reader.read_uint16("Bits Per Sample"))

  if format_tag != nil && format_tag != 1 && chunk_size > 16
    extension_size_field = field_reader.read_uint16("Extension Size")
    extension_size = extension_size_field.value

    display_chunk_section_separator
    display_field(extension_size_field)

    if extension_size != nil && extension_size > 0
      field_reader.with_byte_limit(extension_size) do
        if format_tag == 65534
          display_field(field_reader.read_uint16("Valid Bits Per Sample"))
          display_field(field_reader.read_bitfield("Speaker Mapping", 4))
          display_field(field_reader.read_guid("Sub Format GUID"))

          if field_reader.remaining_byte_limit > 0
            display_field(field_reader.read_bytes("Extra Extension Bytes", field_reader.remaining_byte_limit))
          end
        else
          display_field(field_reader.read_bytes("Raw Extension", extension_size))
        end
      end
    end
  end

  if field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Extra Bytes", field_reader.remaining_byte_limit))
  end
end


def read_fact_chunk(field_reader, chunk_size)
  display_field(field_reader.read_uint32("Sample Count"))

  if field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Extra Bytes", field_reader.remaining_byte_limit))
  end
end


def read_peak_chunk(field_reader, chunk_size)
  display_field(field_reader.read_uint32("Version"))
  display_field(field_reader.read_uint32("Timestamp"))

  channel_count = field_reader.remaining_byte_limit / 8

  channel_count.times do |i|
    display_field(field_reader.read_float32("Chan. #{i + 1} Value"))
    display_field(field_reader.read_uint32("Chan. #{i + 1} Position"))
  end
end


def read_cue_chunk(field_reader, chunk_size)
  cue_point_count_field = field_reader.read_uint32("Cue Point Count")
  cue_point_count = cue_point_count_field.value
  display_field(cue_point_count_field)

  return if cue_point_count.nil?

  cue_point_count.times do |i|
    # Prevent trailing section separator in output
    break if field_reader.remaining_byte_limit <= 0

    cue_point_number = i + 1

    display_chunk_section_separator
    display_field(field_reader.read_uint32("ID #{cue_point_number}"))
    display_field(field_reader.read_uint32("Position #{cue_point_number}"))
    display_field(field_reader.read_fourcc("Chunk Type #{cue_point_number}"))
    display_field(field_reader.read_uint32("Chunk Start #{cue_point_number}"))
    display_field(field_reader.read_uint32("Block Start #{cue_point_number}"))
    display_field(field_reader.read_uint32("Sample Offset #{cue_point_number}"))
  end

  if field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Extra Bytes", field_reader.remaining_byte_limit))
  end
end


def read_sample_chunk(field_reader, chunk_size)
  display_field(field_reader.read_uint32("Manufacturer"))
  display_field(field_reader.read_uint32("Product"))
  display_field(field_reader.read_uint32("Sample Period"))
  display_field(field_reader.read_uint32("MIDI Unity Note"))
  display_field(field_reader.read_uint32("MIDI Pitch Fraction"))
  display_field(field_reader.read_uint32("SMPTE Format"))
  display_field(field_reader.read_uint32("SMPTE Offset"))

  loop_count_field = field_reader.read_uint32("Sample Loop Count")
  loop_count = loop_count_field.value
  display_field(loop_count_field)
  return if loop_count.nil?

  sampler_specific_data_size_field = field_reader.read_uint32("Sampler Data Size")
  sampler_specific_data_size = sampler_specific_data_size_field.value
  display_field(sampler_specific_data_size_field)
  return if sampler_specific_data_size.nil?

  loop_count.times do |i|
    # Prevent trailing section separator in output
    break if field_reader.remaining_byte_limit <= 0

    loop_number = i + 1

    display_chunk_section_separator
    display_field(field_reader.read_uint32("Loop Identifier #{loop_number}"))
    display_field(field_reader.read_uint32("Type #{loop_number}"))
    display_field(field_reader.read_uint32("Start Sample Frame #{loop_number}"))
    display_field(field_reader.read_uint32("End Sample Frame #{loop_number}"))
    display_field(field_reader.read_uint32("Fraction #{loop_number}"))
    display_field(field_reader.read_uint32("Play Count #{loop_number}"))
  end

  if sampler_specific_data_size > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Sampler Specific Data", sampler_specific_data_size))
  end

  if field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Extra Bytes", field_reader.remaining_byte_limit))
  end
end


def read_instrument_chunk(field_reader, chunk_size)
  display_field(field_reader.read_uint8("Unshifted Note"))
  display_field(field_reader.read_int8("Fine Tune"))
  display_field(field_reader.read_int8("Gain"))
  display_field(field_reader.read_uint8("Low Note"))
  display_field(field_reader.read_uint8("High Note"))
  display_field(field_reader.read_uint8("Low Velocity"))
  display_field(field_reader.read_uint8("High Velocity"))

  if field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    display_field(field_reader.read_bytes("Extra Bytes", field_reader.remaining_byte_limit))
  end
end


def read_list_chunk(field_reader, chunk_size)
  list_type_field = field_reader.read_fourcc("List Type")
  display_field(list_type_field)

  while field_reader.remaining_byte_limit > 0
    display_chunk_section_separator
    child_chunk_id_field = field_reader.read_fourcc("Child Chunk ID")
    display_field(child_chunk_id_field)

    child_chunk_size_field = field_reader.read_uint32("Child Chunk Size")
    child_chunk_size = child_chunk_size_field.value
    display_field(child_chunk_size_field)
    return if child_chunk_size.nil?

    field_reader.with_byte_limit(child_chunk_size) do
      if list_type_field.value == "adtl"
        display_field(field_reader.read_uint32("Cue Point ID"))

        if child_chunk_id_field.value == "ltxt"
          display_field(field_reader.read_uint32("Sample Length"))
          display_field(field_reader.read_fourcc("Purpose"))
          display_field(field_reader.read_uint16("Country"))
          display_field(field_reader.read_uint16("Language"))
          display_field(field_reader.read_uint16("Dialect"))
          display_field(field_reader.read_uint16("Code Page"))

          if child_chunk_size > 20
            display_field(field_reader.read_bytes("Text", child_chunk_size - 20))
          end
        else
          display_field(field_reader.read_null_terminated_string("Content", child_chunk_size - 4))
        end
      else   # INFO, and any unknown list type
        display_field(field_reader.read_null_terminated_string("Content", child_chunk_size))
      end
    end

    if child_chunk_size.odd?
      display_field(field_reader.read_padding_byte("Padding Byte"))
    end
  end
end


def read_data_chunk(field_reader, chunk_size)
  intro_byte_count = [32, chunk_size].min

  if intro_byte_count > 0
    display_field(field_reader.read_bytes("First #{intro_byte_count} Bytes", intro_byte_count))
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
  class ByteLimitExhaustedError < StandardError; end
  private_constant :ByteLimitExhaustedError

  def initialize(file)
    @file = file

    max_file_size = (2 ** 32) + 8
    @byte_limits = [max_file_size]
  end

  def with_byte_limit(byte_limit)
    begin
      push_byte_limit(byte_limit)
      yield
    rescue ByteLimitExhaustedError
      # Do nothing; error is rescued to prevent propagation
    ensure
      pop_byte_limit
    end
  end

  def remaining_byte_limit
    @byte_limits.last
  end

  def read_int8(label)
    read_field(label: label,
               byte_count: 1,
               type: "int8",
               parser: lambda {|bytes| bytes.join.unpack("c").first })
  end

  def read_uint8(label)
    read_field(label: label,
               byte_count: 1,
               type: "uint8",
               parser: lambda {|bytes| bytes.join.unpack("C").first })
  end

  def read_uint16(label)
    read_field(label: label,
               byte_count: 2,
               type: "uint16",
               parser: lambda {|bytes| bytes.join.unpack("v").first })
  end

  def read_uint32(label)
    read_field(label: label,
               byte_count: 4,
               type: "uint32",
               parser: lambda {|bytes| bytes.join.unpack("V").first })
  end

  def read_float32(label)
    read_field(label: label,
               byte_count: 4,
               type: "float32",
               parser: lambda {|bytes| bytes.join.unpack("e").first })
  end

  def read_fourcc(label)
    read_field(label: label,
               byte_count: 4,
               type: "FourCC",
               parser: lambda {|bytes| bytes.join })
  end

  def read_null_terminated_string(label, byte_count)
    read_field(label: label,
               byte_count: byte_count,
               type: "C String",
               parser: lambda {|bytes| bytes.join.unpack("Z#{byte_count}").first })
  end

  def read_bitfield(label, byte_count)
    read_field(label: label,
               byte_count: byte_count,
               type: "Bit field",
               parser: lambda {|bytes| "0x#{bytes.reverse.map {|byte| byte.unpack("H2")}.join}"})
  end

  def read_guid(label)
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

    read_field(label: label,
               byte_count: 16,
               type: "GUID",
               parser: parser_lambda)
  end

  def read_bytes(label, byte_count)
    read_field(label: label,
               byte_count: byte_count,
               type: "bytes",
               parser: lambda {|bytes| "N/A" })
  end

  def read_padding_byte(label)
    read_field(label: label,
               byte_count: 1,
               type: "byte",
               parser: lambda {|bytes| bytes.join.unpack("C").first })
  end

  def skip_bytes(byte_count)
    clamped_byte_count = [byte_count, @byte_limits.last].min
    string = @file.sysread(clamped_byte_count)

    decrement_byte_limits(string.length)

    string.length
  end

  private

  def push_byte_limit(byte_limit)
    clamped_byte_limit = [byte_limit, @byte_limits.last].min
    @byte_limits.push(clamped_byte_limit)
  end

  def pop_byte_limit
    @byte_limits.pop
  end

  def decrement_byte_limits(byte_count)
    @byte_limits.map! {|byte_limit| byte_limit - byte_count}
  end

  def read_field(label: nil, byte_count: nil, type: nil, parser: nil)
    bytes = read_field_bytes(byte_count)

    if bytes.last.nil?
      value = nil
    else
      value = parser.call(bytes)
    end

    Field.new(label: label, type: type, value: value, bytes: bytes)
  end

  def read_field_bytes(byte_count)
    if @byte_limits.last <= 0
      raise ByteLimitExhaustedError
    end

    bytes = [nil] * byte_count
    clamped_byte_count = [byte_count, @byte_limits.last].min

    clamped_byte_count.times do |i|
      bytes[i] = @file.sysread(1)
      decrement_byte_limits(1)
    end

    bytes
  end
end


class Field
  def initialize(label: nil, type: nil, value: nil, bytes: nil)
    @label = label
    @type = type
    @value = value
    @bytes = bytes
  end

  attr_reader :label, :type, :value, :bytes

  def incomplete?
    @bytes.last.nil?
  end
end


def display_chunk_header(chunk_id_field, chunk_size_field)
  title = "#{chunk_id_field.value.inspect} Chunk"

  if chunk_id_field.value == "RIFF"
    title += " Header"
  end

  puts title
  puts "================================================================================"

  display_field(chunk_id_field)

  if chunk_size_field != nil
    display_field(chunk_size_field)
    display_chunk_section_separator
  end
end


def display_field(field)
  label_lines = [field.label + ":"]
  type_lines = [field.type]

  if field.incomplete?
    value_lines = ["Incomplete"]
  elsif field.type == "FourCC" || field.type == "C String"
    # Wrap the value in quotes and show character codes for non-display characters
    formatted_value = field.value.inspect

    value_lines = formatted_value.chars[1..-1].each_slice(18).map {|line| line.join}
    value_lines.first.prepend("\"")
    value_lines[1..-1].each {|line| line.prepend(" ")}
  else
    # This branch exists to avoid wrapping a value in quotes when it semantically
    # is not a String but happens to be contained in a String object (e.g. a bit field,
    # GUID, etc).
    formatted_value = field.value.to_s

    value_lines = formatted_value.chars.each_slice(19).map {|line| line.join}
  end

  formatted_bytes = field.bytes.map {|byte| byte.nil? ? "__" : byte.unpack("H2").first }
  bytes_lines = formatted_bytes.each_slice(8).map {|line| line.join(" ")}

  line_count = [value_lines.length, bytes_lines.length].max

  line_count.times do |i|
    puts "#{(label_lines[i] || "").ljust(22)} "\
         "#{(type_lines[i] || "").ljust(9)} | "\
         "#{(value_lines[i] || "").ljust(19)} | "\
         "#{(bytes_lines[i] || "")}"
  end
end


def display_chunk_section_separator
  puts "---------------------------------+---------------------+------------------------"
end


main

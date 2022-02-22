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
  file = File.open(ARGV[0], "rb")
  field_reader = FieldReader.new(file)

  begin
    puts ""

    while true
      chunk_id_data = field_reader.read_fourcc
      chunk_size_data = field_reader.read_uint32

      display_chunk_header(chunk_id_data, chunk_size_data)

      send(CHUNK_BODY_READERS[chunk_id_data[:parsed_value]], field_reader, chunk_size_data[:parsed_value])

      # Read padding byte if necessary
      if chunk_size_data[:parsed_value].odd? && chunk_id_data[:parsed_value] != "RIFF"
        display_line("Padding Byte", field_reader.read_padding_byte)
      end

      puts ""
      puts ""
    end
  rescue EOFError
    # Swallow the error and do nothing to avoid an error being shown in the output,
    # since the normal expected case is that EOFError will be raised once the end
    # of the file is reached.
  ensure
    file.close
  end
end


def display_line(label, field)
  parsed_value = field[:parsed_value]
  bytes = field[:bytes]
  data_type = field[:type_label]

  if data_type == "FourCC" || data_type == "C String"
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
  display_line("Chunk ID", chunk_id)
  display_line("Chunk size", chunk_size)
  display_chunk_section_separator
end


def display_chunk_section_separator
  puts "----------------------------------+------------+----------------------------------"
end


def read_riff_chunk_header(field_reader, chunk_size)
  display_line("Form type", field_reader.read_fourcc)
end


def read_format_chunk(field_reader, chunk_size)
  audio_format_code = field_reader.read_uint16
  display_line("Audio format", audio_format_code)
  display_line("Channels", field_reader.read_uint16)
  display_line("Sample rate", field_reader.read_uint32)
  display_line("Byte rate", field_reader.read_uint32)
  display_line("Block align", field_reader.read_uint16)
  display_line("Bits per sample", field_reader.read_uint16)

  bytes_read_so_far = 16

  if audio_format_code[:parsed_value] != 1 && chunk_size > 16
    extension_size_data = field_reader.read_uint16
    display_line("Extension size", extension_size_data)
    bytes_read_so_far += 2

    if extension_size_data[:parsed_value] > 0
      if audio_format_code[:parsed_value] == 65534
        display_line("Valid bits per sample", field_reader.read_uint16)
        display_line("Speaker mapping", field_reader.read_bitfield(4))
        display_line("Sub format GUID", field_reader.read_guid)

        extra_byte_count = extension_size_data[:parsed_value] - 22
        if extra_byte_count > 0
          display_line("Extra extension bytes", field_reader.read_bytes(extra_byte_count))
        end
      else
        display_line("Raw extension", field_reader.read_bytes(extension_size_data[:parsed_value]))
      end
    end

    bytes_read_so_far += extension_size_data[:parsed_value]
  end

  extra_byte_count = chunk_size - bytes_read_so_far
  if extra_byte_count > 0
    display_line("Extra bytes", field_reader.read_bytes(extra_byte_count))
  end
end


def read_fact_chunk(field_reader, chunk_size)
  display_line("Sample count", field_reader.read_uint32)

  if chunk_size > 4
    display_line("Extra bytes", field_reader.read_bytes(chunk_size - 4))
  end
end


def read_peak_chunk(field_reader, chunk_size)
  display_line("Version", field_reader.read_uint32)
  display_line("Timestamp", field_reader.read_uint32)

  ((chunk_size - 8) / 8).times do |i|
    display_line("Chan. #{i + 1} Value", field_reader.read_float32)
    display_line("Chan. #{i + 1} Position", field_reader.read_uint32)
  end
end


def read_cue_chunk(field_reader, chunk_size)
  cue_point_count = field_reader.read_uint32
  display_line("Cue point count", cue_point_count)

  bytes_remaining = chunk_size - 4

  cue_point_count[:parsed_value].times do |i|
    display_line("ID #{i + 1}", field_reader.read_uint32)
    display_line("Position #{i + 1}", field_reader.read_uint32)
    display_line("Chunk type #{i + 1}", field_reader.read_fourcc)
    display_line("Chunk start #{i + 1}", field_reader.read_uint32)
    display_line("Block start #{i + 1}", field_reader.read_uint32)
    display_line("Sample offset #{i + 1}", field_reader.read_uint32)
    bytes_remaining -= 24
  end

  if bytes_remaining > 0
    display_line("Extra bytes", field_reader.read_bytes(bytes_remaining))
  end
end


def read_sample_chunk(field_reader, chunk_size)
  display_line("Manufacturer", field_reader.read_uint32)
  display_line("Product", field_reader.read_uint32)
  display_line("Sample Period", field_reader.read_uint32)
  display_line("MIDI Unity Note", field_reader.read_uint32)
  display_line("MIDI Pitch Fraction", field_reader.read_uint32)
  display_line("SMPTEFormat", field_reader.read_uint32)
  display_line("SMPTEOffset", field_reader.read_uint32)

  sample_loops_bytes = field_reader.read_uint32
  loop_count = sample_loops_bytes[:parsed_value]
  display_line("Sample Loops", sample_loops_bytes)

  sampler_specific_data_size_bytes = field_reader.read_uint32
  sampler_specific_data_size = sampler_specific_data_size_bytes[:parsed_value]
  display_line("Sampler Data Size", sampler_specific_data_size_bytes)

  loop_count.times do |i|
    display_chunk_section_separator
    puts "Loop ##{i + 1}:"
    display_line("Identifier", field_reader.read_uint32)
    display_line("Type", field_reader.read_uint32)
    display_line("Start", field_reader.read_uint32)
    display_line("End", field_reader.read_uint32)
    display_line("Fraction", field_reader.read_uint32)
    display_line("Play Count", field_reader.read_uint32)
  end

  if sampler_specific_data_size > 0
    display_chunk_section_separator
    display_line("Sampler specific data", field_reader.read_bytes(sampler_specific_data_size))
  end

  extra_byte_count = chunk_size - 36 - (loop_count * 24) - sampler_specific_data_size_bytes[:parsed_value]
  if (extra_byte_count > 0)
    display_line("Extra bytes", field_reader.read_bytes(extra_byte_count))
  end
end


def read_instrument_chunk(field_reader, chunk_size)
  display_line("Unshifted Note", field_reader.read_uint8)
  display_line("Fine Tune", field_reader.read_int8)
  display_line("Gain", field_reader.read_int8)
  display_line("Low Note", field_reader.read_uint8)
  display_line("High Note", field_reader.read_uint8)
  display_line("Low Velocity", field_reader.read_uint8)
  display_line("High Velocity", field_reader.read_uint8)

  extra_data_size = chunk_size - 7
  if extra_data_size > 0
    display_line("Extra bytes", field_reader.read_bytes(extra_data_size))
  end
end


def read_list_chunk(field_reader, chunk_size)
  list_type = field_reader.read_fourcc
  display_line("List Type", list_type)

  bytes_remaining = chunk_size - 4

  while bytes_remaining > 0
    display_chunk_section_separator
    child_chunk_id = field_reader.read_fourcc
    display_line("Child Chunk ID", child_chunk_id)

    child_chunk_size_bytes = field_reader.read_uint32
    child_chunk_size = child_chunk_size_bytes[:parsed_value]

    display_line("Child Chunk Size", child_chunk_size_bytes)

    if list_type[:parsed_value] == "adtl"
      display_line("Cue Point ID", field_reader.read_uint32)

      if child_chunk_id[:parsed_value] == "ltxt"
        display_line("Sample Length", field_reader.read_uint32)
        display_line("Purpose", field_reader.read_fourcc)
        display_line("Country", field_reader.read_uint16)
        display_line("Language", field_reader.read_uint16)
        display_line("Dialect", field_reader.read_uint16)
        display_line("Code Page", field_reader.read_uint16)

        if child_chunk_size > 20
          display_line("Text", field_reader.read_bytes(child_chunk_size - 20))
        end
      else
        display_line("Content", field_reader.read_null_terminated_string(child_chunk_size - 4))
      end

      bytes_remaining -= (child_chunk_size + 8)
    else   # INFO, and any unknown list type
      display_line("Content", field_reader.read_null_terminated_string(child_chunk_size))

      bytes_remaining -= (child_chunk_size + 8)
    end

    if child_chunk_size.odd?
      display_line("Padding Byte", field_reader.read_padding_byte)
      bytes_remaining -= 1
    end
  end
end


def read_data_chunk(field_reader, chunk_size)
  intro_byte_count = [10, chunk_size].min

  if intro_byte_count > 0
    display_line("Data Start", field_reader.read_bytes(intro_byte_count))
  end

  if intro_byte_count < chunk_size
    field_reader.skip_bytes(chunk_size - intro_byte_count)
  end
end


def read_unrecognized_chunk(field_reader, chunk_size)
  if chunk_size > 0
    puts "(chunk body omitted)"
    field_reader.skip_bytes(chunk_size)
  end
end


class FieldReader
  def initialize(file)
    @file = file
  end

  def read_int8
    read_field(byte_count: 1,
               type_label: "int_8",
               parser: lambda {|bytes| bytes.join.unpack("c").first })
  end

  def read_uint8
    read_field(byte_count: 1,
               type_label: "uint_8",
               parser: lambda {|bytes| bytes.join.unpack("C").first })
  end

  def read_uint16
    read_field(byte_count: 2,
               type_label: "uint_16",
               parser: lambda {|bytes| bytes.join.unpack("v").first })
  end

  def read_uint32
    read_field(byte_count: 4,
               type_label: "uint_32",
               parser: lambda {|bytes| bytes.join.unpack("V").first })
  end

  def read_float32
    read_field(byte_count: 4,
               type_label: "float_32",
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
               parser: lambda {|bytes| bytes.reverse.map {|byte| byte.unpack("B8")}.join })
  end

  def read_guid
    read_field(byte_count: 16,
               type_label: "GUID",
               parser: lambda {|bytes| "0x#{bytes.map {|byte| byte.unpack("H2")}.join}" })
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
    @file.sysread(byte_count)
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
    end

    bytes
  end
end


main

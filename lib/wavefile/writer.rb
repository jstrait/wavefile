module WaveFile
  class Writer
    def initialize(file_name, format)
      @file = File.open(file_name, "wb")
      @format = format

      @samples_written = 0
      @pack_code = PACK_CODES[format.bits_per_sample]
      write_header(0)
    end

    def write(buffer)
      samples = buffer.convert(@format).samples

      @file.syswrite(samples.flatten.pack(@pack_code))
      @samples_written += samples.length
    end

    def close()
      @file.sysseek(0)
      write_header(@samples_written)
      
      @file.close()
    end

    attr_reader :file_name, :format, :samples_written

  private

    def write_header(sample_count)
      header = CHUNK_IDS[:header]
      header += [HEADER_BYTE_LENGTH + sample_count].pack("V")
      header += WAVEFILE_FORMAT_CODE
      header += CHUNK_IDS[:format]
      header += [FORMAT_CHUNK_BYTE_LENGTH].pack("V")
      header += [PCM].pack("v")
      header += [@format.channels].pack("v")
      header += [@format.sample_rate].pack("V")
      header += [@format.byte_rate].pack("V")
      header += [@format.block_align].pack("v")
      header += [@format.bits_per_sample].pack("v")
      header += CHUNK_IDS[:data]
      header += [sample_count].pack("V")

      @file.syswrite(header)
    end
  end
end

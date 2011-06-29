module WaveFile
  class Writer
    EMPTY_BYTE = "\000"

    def initialize(file_name, format)
      @file = File.open(file_name, "wb")
      @format = format

      @samples_written = 0
      @pack_code = PACK_CODES[format.bits_per_sample]

      # Note that the correct sizes for the RIFF and data chunks can't be determined
      # until all samples have been written, so this header as written will be incorrect.
      # When close() is called, the correct sizes will be re-written.
      write_header(0)

      if block_given?
        yield(self)
        close()
      end
    end

    def write(buffer)
      samples = buffer.convert(@format).samples

      @file.syswrite(samples.flatten.pack(@pack_code))
      @samples_written += samples.length
    end

    def close()
      # The RIFF specification requires that each chunk be aligned to an even number of bytes,
      # even if the byte count is an odd number. Therefore if an odd number of bytes has been
      # written, write an empty padding byte.
      #
      # See http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/Docs/riffmci.pdf, page 11.
      bytes_written = @samples_written * @format.block_align
      if bytes_written.odd?
        @file.syswrite(EMPTY_BYTE)
      end

      # We can't know what chunk sizes to write for the RIFF and data chunks until all
      # samples have been written, so go back to the beginning of the file and re-write
      # those chunk headers with the correct sizes.
      @file.sysseek(0)
      write_header(@samples_written)
      
      @file.close()
    end

    attr_reader :file_name, :format, :samples_written

  private

    def write_header(sample_count)
      sample_data_byte_count = sample_count * @format.block_align

      # Write the header for the RIFF chunk
      header = CHUNK_IDS[:header]
      header += [HEADER_BYTE_LENGTH + sample_data_byte_count].pack("V")
      header += WAVEFILE_FORMAT_CODE

      # Write the format chunk
      header += CHUNK_IDS[:format]
      header += [FORMAT_CHUNK_BYTE_LENGTH].pack("V")
      header += [PCM].pack("v")
      header += [@format.channels].pack("v")
      header += [@format.sample_rate].pack("V")
      header += [@format.byte_rate].pack("V")
      header += [@format.block_align].pack("v")
      header += [@format.bits_per_sample].pack("v")

      # Write the header for the data chunk
      header += CHUNK_IDS[:data]
      header += [sample_data_byte_count].pack("V")

      @file.syswrite(header)
    end
  end
end

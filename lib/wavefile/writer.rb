module WaveFile
  # Provides the ability to write data to a wave file.
  class Writer

    # Padding value written to the end of chunks whose payload is an odd number of bytes. The RIFF
    # specification requires that each chunk be aligned to an even number of bytes, even if the byte
    # count is an odd number.
    #
    # See http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/Docs/riffmci.pdf, page 11.
    EMPTY_BYTE = "\000"

    # The number of bytes at the beginning of a wave file before the sample data in the data chunk
    # starts, assuming this canonical format:
    #
    # RIFF Chunk Header (12 bytes)
    # Format Chunk (No Extension) (16 bytes)
    # Data Chunk Header (8 bytes)
    #
    # All wave files written by Writer use this canonical format.
    CANONICAL_HEADER_BYTE_LENGTH = 36


    # Returns a constructed Writer object which is available for writing sample data to the specified
    # file (via the write method). When all sample data has been written, the Writer should be closed.
    # Note that the wave file being written to will NOT be valid (and playable in other programs) until
    # the Writer has been closed.
    #
    # If a block is given to this method, sample data can be written inside the given block. When the
    # block terminates, the Writer will be automatically closed (and no more sample data can be written).
    #
    # If no block is given, then sample data can be written until the close method is called.
    def initialize(file_name, format)
      @file_name = file_name
      @file = File.open(file_name, "wb")
      @format = format

      @samples_written = 0
      @pack_code = PACK_CODES[format.bits_per_sample]

      # Note that the correct sizes for the RIFF and data chunks can't be determined
      # until all samples have been written, so this header as written will be incorrect.
      # When close is called, the correct sizes will be re-written.
      write_header(0)

      if block_given?
        yield(self)
        close
      end
    end


    # Appends the sample data in the given Buffer to the end of the wave file.
    #
    # Returns the number of sample that have been written to the file so far.
    # Raises IOError if the Writer has been closed.
    def write(buffer)
      samples = buffer.convert(@format).samples

      @file.syswrite(samples.flatten.pack(@pack_code))
      @samples_written += samples.length
    end


    # Returns true if the Writer is closed, and false if it is open and available for writing.
    def closed?
      @file.closed?
    end


    # Closes the Writer. After a Writer is closed, no more sample data can be written to it.
    #
    # Note that the wave file will NOT be valid until this method is called. The wave file
    # format requires certain information about the amount of sample data, and this can't be
    # determined until all samples have been written. 
    #
    # Returns nothing.
    # Raises IOError if the Writer is already closed.
    def close
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
      
      @file.close
    end

    attr_reader :file_name, :format

  private

    # Writes the RIFF chunk header, format chunk, and the header for the data chunk. After this
    # method is called the file will be "queued up" and ready for writing actual sample data.
    def write_header(sample_count)
      sample_data_byte_count = sample_count * @format.block_align

      # Write the header for the RIFF chunk
      header = CHUNK_IDS[:riff]
      header += [CANONICAL_HEADER_BYTE_LENGTH + sample_data_byte_count].pack(UNSIGNED_INT_32)
      header += WAVEFILE_FORMAT_CODE

      # Write the format chunk
      header += CHUNK_IDS[:format]
      header += [FORMAT_CHUNK_BYTE_LENGTH].pack(UNSIGNED_INT_32)
      header += [PCM].pack(UNSIGNED_INT_16)
      header += [@format.channels].pack(UNSIGNED_INT_16)
      header += [@format.sample_rate].pack(UNSIGNED_INT_32)
      header += [@format.byte_rate].pack(UNSIGNED_INT_32)
      header += [@format.block_align].pack(UNSIGNED_INT_16)
      header += [@format.bits_per_sample].pack(UNSIGNED_INT_16)

      # Write the header for the data chunk
      header += CHUNK_IDS[:data]
      header += [sample_data_byte_count].pack(UNSIGNED_INT_32)

      @file.syswrite(header)
    end
  end
end

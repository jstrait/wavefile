A pure Ruby gem for reading and writing sound files in Wave format (*.wav). You can use this gem to create Ruby programs that produce audio, such as [drum machine](http://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.


# Example Usage

This is a short example that shows how to append three separate Wave files into a single file:

    require 'wavefile'
    include WaveFile
    
    FILES_TO_APPEND = ["file1.wav", "file2.wav", "file3.wav"]
    SAMPLES_PER_BUFFER = 4096

    Writer.new("append.wav", Format.new(:stereo, 16, 44100) do |writer|
      FILES_TO_APPEND.each do |file_name|
        Reader.new(file_name).each_buffer(SAMPLES_PER_BUFFER) do |buffer|
          writer.write(buffer)
        end
      end
    end

More examples can be [found on the wiki](https://github.com/jstrait/wavefile/wiki).


# Latest Release: v0.4.0

This version is a re-write with a completely new, much improved API. (The old API has been removed). Some improvements due to the new API include:

* Reduced memory consumption, due to not having to load the entire file into memory. In practice, this allows the gem to read/write files that previously would have been prohibitively large.
* Better performance for large files, for the same reason as above.
* Ability to progressively append data to the end of a file, instead of writing the entire file at once.
* Ability to easily read and write data in an arbitrary format, regardless of the file's native format. For example, you can transparently read data out of a 16-bit stereo file as 8-bit mono.
* Automatic file management, similar to how IO.open() works. It's easy to continually read the sample data from a file, passing each buffer to a block, and have the file automatically close when there is no more data left.

Other improvements include:

* Ability to query format metadata of files without opening them, even for formats that this gem can't read or write.
* Support for reading and writing 32-bit PCM files.

However, reading or writing data as floating point (i.e. values between -1.0 and 1.0) won't be supported in v0.4.0 to keep the scope in check. It might be re-added in the future.


# Compatibility

WaveFile has been tested with these Ruby versions, and appears to be compatible with them:

* MRI 1.9.3, 1.9.2, 1.9.1, 1.8.7
* JRuby 1.6.5
* Rubinius 1.2.4
* MacRuby 0.10

If you find any compatibility issues, please let me know by opening a GitHub issue.


# Dependencies

WaveFile has no external dependencies. It is written in pure Ruby, and is entirely self-contained.


# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require 'wavefile'

Note that if you're installing the gem into the default Ruby that comes pre-installed on MacOS (as opposed to a Ruby installed via [RVM](http://beginrescueend.com/)), you should used `sudo gem install wavefile`. Otherwise you might run into a file permission error.

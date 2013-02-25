A pure Ruby gem for reading and writing sound files in Wave format (*.wav).

You can use this gem to create Ruby programs that produce audio, such as [drum machine](http://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.


# Example Usage

This is a short example that shows how to append three separate Wave files into a single file:

    require 'wavefile'
    include WaveFile
    
    FILES_TO_APPEND = ["file1.wav", "file2.wav", "file3.wav"]
    SAMPLES_PER_BUFFER = 4096

    Writer.new("append.wav", Format.new(:stereo, :pcm_16, 44100)) do |writer|
      FILES_TO_APPEND.each do |file_name|
        Reader.new(file_name).each_buffer(SAMPLES_PER_BUFFER) do |buffer|
          writer.write(buffer)
        end
      end
    end

More examples can be [found on the wiki](https://github.com/jstrait/wavefile/wiki).


# Features

* Ability to read and write Wave files with any number of channels in the following formats:
  * PCM (8, 16, and 32 bits per sample)
  * Floating Point (32 and 64 bits per sample)
* Ability to read sample data from a file in any of the supported formats, regardless of the file's actual sample format

            # Sample data will be returned as 32-bit floating point samples,
            # regardless of the actual sample format in the file.
            Reader.new("some_file.wav", Format.new(:mono, :float_32, 44100))

* Automatic file management, similar to how `IO.open` works. That is, you can open a file for reading or writing, and if a block is given, the file will automatically be closed when the block exits.

        Writer.new("some_file.wav", Format.new(:mono, :pcm_16, 44100)) do |writer|
          # write some sample data
        end
        # At this point, the writer will automatically be closed, no need to do it manually

* Ability to query metadata about Wave files (sample rate, number of channels, number of sample frames, etc.), including files that are in a format this gem can't read or write.
* Pure Ruby, so no need to compile a separate extension in order to use it.


# Current Release: v0.5.0

This release includes these improvements:

* Support for reading and writing Wave files containing 32 and 64-bit floating point sample data.
* Support for buffers that contain floating point data (i.e., samples between -1.0 and 1.0), including the ability to convert to and from PCM buffers.
* A new `Duration` object which can be used to calculate the playback time given a sample rate and number of sample frames.
* New attributes: `Reader.current_sample_frame`, `Reader.total_sample_frames`, and `Writer.total_sample_frames`.
* Ability to get these attributes as a `Duration` object as well: `Reader.total_duration`, `Writer.total_duration`.
* The 2nd argument to `Format.new` now indicates the sample format, not the bits per sample. For example, `:pcm_16` or `:float_32` instead of `8` or `16`. For backwards compatibility, `8`, `16`, and `32` can still be given and will be interpreted as `:pcm_8`, `:pcm_16`, and `:pcm_32`, but this support might be removed in the future.
* Bug fix: Wave files are no longer corrupted when an unhandled exception occurs inside a `Writer` block. (Thanks to [James Tunnell](https://github.com/jamestunnell) for reporting and fixing this).
* Bug fix: `Writer.file_name` now returns the file name, instead of always returning nil (Thanks to [James Tunnell](https://github.com/jamestunnell) for reporting this).

This release also includes changes that are not backwards compatible with v0.4.0. (Until version v1.0, no guarantees to avoid this will be made, but I'll try to have a good reason before doing so).

* `Info.duration` now returns a `Duration` object, instead of a hash.
* `Info.sample_count` has been renamed `sample_frame_count`.
* Some constants in the `WaveFile` module have changed. (In general, you should treat these as internal to this gem and not use them in your own program).


# Compatibility

WaveFile has been tested with these Ruby versions, and appears to be compatible with them:

* MRI 2.0.0, 1.9.3, 1.9.2, 1.9.1, 1.8.7
* JRuby 1.7.3
* Rubinius 1.2.4
* MacRuby 0.12

If you find any compatibility issues, please let me know by opening a GitHub issue.


# Dependencies

WaveFile has no external dependencies. It is written in pure Ruby, and is entirely self-contained.


# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require 'wavefile'

Note that if you're installing the gem into the default Ruby that comes pre-installed on MacOS (as opposed to a Ruby installed via [RVM](http://beginrescueend.com/) or [rbenv](https://github.com/sstephenson/rbenv/)), you should used `sudo gem install wavefile`. Otherwise you might run into a file permission error.


# Contributing

1. Fork my repo
2. Create a branch for your changes
3. Add your changes, and please include tests
4. Make sure the tests pass by running `rake test`
5. Create a pull request

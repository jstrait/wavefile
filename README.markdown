A pure Ruby gem for reading and writing sound files in Wave format (*.wav).

You can use this gem to create Ruby programs that work with audio, such as a [command-line drum machine](http://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.

For more info, check out the website: <http://wavefilegem.com/>

# Example Usage

This is a short example that shows how to append three separate Wave files into a single file:

    require 'wavefile'
    include WaveFile
    
    FILES_TO_APPEND = ["file1.wav", "file2.wav", "file3.wav"]

    Writer.new("append.wav", Format.new(:stereo, :pcm_16, 44100)) do |writer|
      FILES_TO_APPEND.each do |file_name|
        Reader.new(file_name).each_buffer do |buffer|
          writer.write(buffer)
        end
      end
    end

More examples can be found at <http://wavefilegem.com/examples>.


# Features

This gem lets you read and write audio data! You can use it to create Ruby programs that work with sound.

* Read and write Wave files with any number of channels, in the following formats:
  * PCM (8, 16, 24, and 32 bits per sample)
  * Floating Point (32 and 64 bits per sample)
  * These formats can also be read from both "vanilla" Wave files, and also files using `WAVEFORMATEXTENSIBLE` format.
* Seamlessly convert between sample formats.
  * You can read sample data from a file in any format supported by this gem, regardless of how the sample data is stored in the actual file:

            # Sample data will be returned as 32-bit floating point samples,
            # regardless of the actual sample format in the file.
            Reader.new("some_file.wav", Format.new(:mono, :float_32, 44100))

  * Or, you can create sample data in one format, but write it to a file in a different format. For example, generate samples as floats between -1.0 and 1.0 for convenience, but write them to disk as 16-bit PCM samples:

            # Generate a buffer of floating point samples between -1.0 and 1.0
            my_samples = generate_float_samples()  # You would write this method yourself
            buffer = Buffer.new(my_samples, Format.new(:mono, :float_32, 41000))
            
            # Write them to a file as 16-bit PCM samples
            Writer.new("some_file.wav", Format.new(:mono, :pcm_16, 44100)) do |writer|
              writer.write(buffer)
            end

* Automatic file management, similar to how `IO.open` works. That is, you can open a file for reading or writing, and if a block is given, the file will automatically be closed when the block exits.

        Writer.new("some_file.wav", Format.new(:mono, :pcm_16, 44100)) do |writer|
          # write some sample data
        end
        # At this point, the writer will automatically be closed, no need to do it manually

* Ability to query metadata about Wave files (sample rate, number of channels, number of sample frames, etc.), including files that are in a format this gem can't read or write.
* Written in pure Ruby, so it's easy to include in your program. There's no need to compile a separate extension in order to use it.


# Current Release: v0.8.0

Released on ____, this version includes these changes:

* Wave files with the format WAVEFORMATEXTENSIBLE can now be read. Some notes:
  * Only WAVEFORMATEXTENSIBLE files with sub format of PCM or IEEE_FLOAT can be read.
  * The channel mapping fields are not exposed by the gem
  * It's not possible to write files with WAVEFORMATEXTENSIBLE format
  * The number of valid bits per sample must match the sample container size. For example, if a file has a container size of 24 bits and each sample is 24 bits, then it can be read. If the container size is 32 bits and each sample is 24 bits, it _can't_ be read.
* `Reader.new()` and `Writer.new()` now can be constructed with an open IO instance. Previously, only a file name (given by a String) could be given. The first argument of each constructor indicates where to read/write: if the argument is an IO instance it will be used for reading/writing, and if the argument is a String, it will be treated as the name of the file to open for reading/writing. Thanks to [@taf2](https://github.com/taf2) for suggesting this feature and providing a pull request.
* `Reader.each_buffer()` no longer requires the user to specify the size of each buffer. A specific size in sample frames can still be given (for example, `Reader.each_buffer(1024)`), but if no buffer size is given a default value will be used.
* `Duration` now includes an overridden definition of `==`, so that two `Duration` objects will evaluate to equal if they represent the same amount of time. Thanks to [Christopher Smith](https://github.com/chrylis) for suggesting this feature.
* `Reader.file_name` and `Writer.file_name` have been removed. When a `Reader` or `Writer` instance is constructed from an `IO` instance, this field wouldn't have a sensible value. Since I'm not sure of a specific reason for why this field would be used, removing it.
* A `ReaderClosedError` is now raised when attempting to read from a closed `Reader` instance, instead of `IOError`.


# Compatibility

WaveFile has been tested with these Ruby versions, and appears to be compatible with them:

* MRI 2.4.0, 2.3.3, 2.2.6, 2.1.10, 2.0, 1.9.3

1.9.3 is the minimum supported Ruby version.

If you find any compatibility issues, please let me know by opening a GitHub issue.


# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require 'wavefile'

Note that if you're installing the gem into the default Ruby that comes pre-installed on MacOS (as opposed to a Ruby installed via [RVM](http://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv/)), you should used `sudo gem install wavefile`. Otherwise you might run into a file permission error.


# Dependencies

WaveFile has no external dependencies when used as a gem. It is written in pure Ruby, and is entirely self-contained.

However, it does have dependencies for local development, in order to run the tests. See below in section "Local Development".


# Local Development

## Running the Tests

First, install the required development/test dependencies:

    bundle install

Then, to run the tests:

    bundle exec rake test

## Generate test fixtures

This isn't required to the run the tests because the fixture files are checked in the repository, but is needed to change one of the fixture `*.wav` files. These files are generated from `*.yml` config files defined in `/tools`.

    rake test:create_fixtures

## Generating RDoc Documentation

    rake rdoc


# Contributing

1. Fork my repo
2. Create a branch for your changes
3. Add your changes, and please include tests
4. Make sure the tests pass by running `rake test`
5. Create a pull request

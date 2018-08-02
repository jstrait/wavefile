A Ruby gem for reading and writing sound files in Wave format (*.wav).

You can use this gem to create Ruby programs that work with audio, such as a [command-line drum machine](https://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.

For more info, check out the website: <http://wavefilegem.com/>

# Example Usage

This short example shows how to append three separate Wave files into a single file:

```ruby
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
```

More examples can be found at <http://wavefilegem.com/examples>.


# Features

This gem lets you read and write audio data! You can use it to create Ruby programs that work with sound.

* Read and write Wave files with any number of channels, in integer PCM (8/16/24/32 bits per sample) or floating point PCM (32/64 bits per sample) format.
* Seamlessly convert between sample formats. Read sample data from a file into any format supported by this gem, regardless of how the sample data is stored in the actual file. Or, create sample data in one format (such as floats between -1.0 and 1.0), but write it to a file in a different format (such as 16-bit PCM).
* Automatic file management, similar to how `IO.open` works. That is, you can open a file for reading or writing, and if a block is given, the file will automatically be closed when the block exits.
* Query metadata about Wave files (sample rate, number of channels, number of sample frames, etc.), including files that are in a format this gem can't read or write.
* Written in pure Ruby, so it's easy to include in your program. There's no need to compile a separate extension in order to use it.


# Current Release: v1.0.1

Released on August 2, 2018, this version contains a bug fix: the file(s) written to an arbitrary `IO` instance are no longer corrupt if the initial seek position is greater than 0.


# Previous Release: v1.0.0

Released on June 10, 2018, this version has these changes:

* **Ruby 2.0 or greater is now required** - the gem no longer works in Ruby 1.9.3.
* **Backwards incompatible change:** Calling `Reader.close` on a `Reader` instance that is already closed no longer raises `ReaderClosedError`. Instead, it does nothing. Similarly, calling `Writer.close` on a `Writer` instance that is already closed no longer raises `WriterClosedError`. Thanks to [@kylekyle](https://github.com/kylekyle) for raising this as an issue.
* **Better compatibility when writing Wave files.** `Writer` will now write files using a format called WAVE_FORMAT_EXTENSIBLE where appropriate. This is a behind-the-scenes improvement - for most use cases it won't affect how you use the gem, but can result in better compatibility with other programs.
  * A file will automatically be written using WAVE_FORMAT_EXTENSIBLE format if any of the following are true:
    * It has more than 2 channels
    * It uses integer PCM sample format and the bits per sample is not 8 or 16 (in other words, if the sample format is `:pcm_24` or `:pcm_32`).
    * A specific channel->speaker mapping is given (see below).
* **The channel->speaker mapping field can now be read from files that have it defined.** For example, if a file indicates that the first sound channel should be mapped to the back right speaker, the second channel to the top center speaker, etc., this can be read using the `Reader.format.speaker_mapping` field.
  * Example:
    * ~~~
      reader = Reader.new("4_channel_file.wav")
      puts reader.format.speaker_mapping.inspect  # [:front_left, :front_right, :front_center, :back_center]
      ~~~
  * The channel->speaker mapping field isn't present in all Wave files. (Specifically, it's only present if the file uses WAVE_FORMAT_EXTENSIBLE format). For a non-WAVE_FORMAT_EXTENSIBLE file, `Reader.native_format.speaker_mapping` will be `nil`, to reflect that the channel->speaker mapping is undefined. `Reader.format.speaker_mapping` will use a "sensible" default value for the given number of channels.
* **A channel->speaker mapping array can optionally be given when constructing a `Format` instance.** If not given, a default value will be set for the given number of channels.
  * Example:
    * `Format.new(4, :pcm_16, 44100, speaker_mapping: [:front_left, :front_right, :front_center, :low_frequency])`
* **Errors raised by `Format.new` are improved to provide more detail.**


# Compatibility

WaveFile has been tested with these Ruby versions, and appears to be compatible with them:

* MRI 2.5.1, 2.4.4, 2.3.7, 2.2.10, 2.1.10, 2.0

2.0 is the minimum supported Ruby version.

If you find any compatibility issues, please let me know by opening a GitHub issue.


# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require 'wavefile'

Note that if you're installing the gem into the default Ruby that comes pre-installed on MacOS (as opposed to a Ruby installed via [RVM](http://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv/)), you should used `sudo gem install wavefile`. Otherwise you might run into a file permission error.


# Dependencies

WaveFile has no external dependencies when used as a gem.

However, it does have dependencies for local development, in order to run the tests. See below in section "Local Development".


# Local Development

## Running the Tests

First, install the required development/test dependencies:

    bundle install

Then, to run the tests:

    bundle exec rake test

## Generating test fixtures

The `*.wav` fixtures in `test/fixtures/wave` are generated from `*.yml` files defined in `/test/fixtures/yaml`. To change one of the `*.wav` fixtures, edit the corresponding `*.yml` file, and then run:

    rake test:create_fixtures

Similarly, if you want to add a new `*.wav` fixture, add a new `*.yml` file that describes it in `/test/fixtures/yaml`, and then run the rake command above.

Behind the scenes, `rake test:create_fixtures` runs `tools/fixture_writer.rb`, which is what actually generates each `*.wav` file.


## Generating RDoc Documentation

    rake rdoc


# Contributing

1. Fork my repo
2. Create a branch for your changes
3. Add your changes, and please include tests
4. Make sure the tests pass by running `rake test`
5. Create a pull request

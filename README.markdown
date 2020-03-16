A Ruby gem for reading and writing sound files in Wave format (*.wav).

You can use this gem to create Ruby programs that work with audio, such as a [command-line drum machine](https://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.

For more info, check out the website: <https://wavefilegem.com/>

# Example Usage

This short example shows how to append three separate Wave files into a single file:

```ruby
require "wavefile"
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

More examples can be found at <https://wavefilegem.com/examples>.


# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require "wavefile"

Note that if you're installing the gem into the default Ruby that comes pre-installed on MacOS (as opposed to a Ruby installed via [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv/)), you should used `sudo gem install wavefile`. Otherwise you might run into a file permission error.


# Compatibility

WaveFile has been tested with these Ruby versions, and appears to be compatible with them:

* MRI 2.7.0, 2.6.5, 2.5.7, 2.4.9, 2.3.8, 2.2.10, 2.1.10, 2.0.0-p648

2.0 is the minimum supported Ruby version.

If you find any compatibility issues, please let me know by opening a GitHub issue.


# Dependencies

WaveFile has no external dependencies when used as a gem.

However, it does have dependencies for local development, in order to run the tests. See below in section "Local Development".


# Features

This gem lets you read and write audio data! You can use it to create Ruby programs that work with sound.

* Read and write Wave files with any number of channels, in integer PCM (8/16/24/32 bits per sample) or floating point PCM (32/64 bits per sample) format.
* Seamlessly convert between sample formats. Read sample data from a file into any format supported by this gem, regardless of how the sample data is stored in the actual file. Or, create sample data in one format (such as floats between -1.0 and 1.0), but write it to a file in a different format (such as 16-bit PCM).
* Automatic file management, similar to how `IO.open` works. That is, you can open a file for reading or writing, and if a block is given, the file will automatically be closed when the block exits.
* Query metadata about Wave files (sample rate, number of channels, number of sample frames, etc.), including files that are in a format this gem can't read or write.
* Easy to install, since it's written in pure Ruby. There's no need to compile a separate extension in order to use it.


# Current Release: v1.1.1

Released on December 29, 2019, this version contains this change:

* Removes `warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call` output when reading a file with a `smpl` chunk using Ruby 2.7.0. (And presumably, higher Ruby versions as well, but Ruby 2.7.0 is the most recent Ruby version at the time of this release).


# Previous Release: v1.1.0

Released on January 20, 2019, this version has these changes:

* **Can read `smpl` chunk data from files that contain this kind of chunk.** If a *.wav file contains a `smpl` chunk, then `Reader.sampler_info` will return a `SamplerInfo` instance with the relevant data (or `nil` otherwise). Thanks to [@henrikj242](https://github.com/henrikj242) for suggesting this feature and providing the base implementation.
* **More informative errors raised by `Reader.new`**. When attempting to read an invalid file, the error message now provides more detail about why the file is invalid.
* **Bug Fix**: The master RIFF chunk size for files written by the gem will now take into account padding bytes written for child chunks. For example, when writing a file with a `data` chunk whose body has an odd number of bytes, the master RIFF chunk's size will be 1 byte larger (to take the empty padding byte at the end of the `data` chunk into account).
* **Bug Fix**: If the stated `data` chunk size is larger than the actual number of bytes in the file, `Reader.current_sample_frame` will be correct when attempting to read past the end of the chunk. For example, if a `data` chunk says it has 2000 sample frames, but there are only 1000 sample frames remaining in the file, then after calling `Reader.read(1500)`, `Reader.current_sample_frame` will have a value of `1000`, not `1500`. (This bug did not occur for files in which the data chunk listed the correct size).
* **Bug Fix**: Fixed off-by-one error in the maximum allowed value for `Format#sample rate`. The correct maximum sample rate is now 4_294_967_295; previously it allowed a maximum of 4_294_967_296.

For changes in previous versions, visit <https://github.com/jstrait/wavefile/releases>.


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

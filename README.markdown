A Ruby gem for reading and writing sound files in Wave format (*.wav).

You can use this gem to create Ruby programs that work with audio, such as a [command-line drum machine](https://beatsdrummachine.com). Since it is written in pure Ruby (as opposed to wrapping an existing C library), you can use it without having to compile a separate extension.

For more info, check out the website: <https://wavefilegem.com/>

# Example Usage

This example shows how to append three separate Wave files into a single file:

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

* MRI 3.1.2, 3.0.4, 2.7.6, 2.6.10, 2.5.9, 2.4.10, 2.3.8, 2.2.10, 2.1.10, 2.0.0-p648

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


# Current Release: v1.1.2

Released on TBD, this version fixes several edge case bugs related to reading a *.wav file's `"fmt "` chunk. In particular, reading a `"fmt "` chunk that has extra trailing bytes, reading a `"fmt "` chunk in WAVE_FORMAT_EXTENSIBLE format whose extension is incomplete or has extra trailing bytes, and reading a `"fmt "` chunk whose extension is too large to fit in the chunk. In short, some valid files that were previously rejected can now be read, and some invalid files are handled more properly.

The full details:

* **Bug Fix:** Files that have extra bytes at the end of the `"fmt "` chunk can now be read.

    If the format code is `1`, the `"fmt "` chunk has extra bytes if the chunk body size is greater than 16. Otherwise, "extra bytes" means the chunk contains bytes after the chunk extension (not including the required padding byte for an odd-sized chunk).

    Previously, attempting to open certain files like this via `Reader.new` would result in `InvalidFormatError` being raised with a misleading `"Not a supported wave file. The format chunk extension is shorter than expected."` message. (If the format code was `1`, the `"fmt "` chunk wouldn't actually have an extension; for other format codes the extension might actually be the expected size or larger). When reading a file like this, any extra data in the `"fmt "` chunk beyond what is expected based on the relevant format code will now be ignored.

  * There was a special case where a file like this _could_ be opened correctly. If the format code was `1`, and the value of bytes 16 and 17 (0-based), when interpreted as a 16-bit unsigned little-endian integer, happened to be the same as the number of subsequent bytes in the chunk, the file could be opened without issue. For example, if the `"fmt "` chunk size was `22`, the format code was `1`, and the value of bytes 16 and 17 was `4` (when interpreted as a 16-bit unsigned little-endian integer), the file could be opened correctly.
  * There was another special case where `InvalidFormatError` would be incorrectly raised, but the error message would be different (and also misleading). If the format code was `1`, and there was exactly 1 extra byte in the `"fmt "` chunk (i.e. the chunk size was 17), the error message would be `"Not a supported wave file. The format chunk is missing an expected extension."` This was misleading because when the format code is `1`, the `"fmt "` chunk doesn't have an extension.
  * Thanks to [@CromonMS](https://github.com/CromonMS) for reporting this as an issue.

* **Bug Fix:** Files in WAVE_FORMAT_EXTENSIBLE format that have an oversized `"fmt "` chunk extension (i.e. larger than 22 bytes) can now be read.

    This is similar but different from the bug above; that bug refers to extra bytes _after_ the chunk extension, while this bug refers to extra bytes _inside_ the chunk extension. Previously, a `Reader` instance could be constructed for a file like this, but `Reader#native_format#sub_audio_format_guid` would have an incorrect value, and sample data could not be read from the file. After this fix, this field will have the correct value, and if it is one of the supported values then sample data can be read. Any extra data at the end of the chunk extension will be ignored.

    Implicit in this scenario is that the `"fmt "` chunk has a stated size large enough to fit the oversized extension. For cases where it doesn't, see the next bug fix below.

* **Bug Fix:** More accurate message on the `InvalidFormatError` raised when reading a file whose `"fmt "` chunk extension is too large to fit in the chunk.

    The message will now correctly state that the chunk extension is too large, rather than `"Not a supported wave file. The format chunk extension is shorter than expected."`. As an example of what "too large" means, if a `"fmt "` chunk has a size of 40 bytes, then any chunk extension larger than 22 bytes will be too large and overflow out of the chunk, since all `"fmt "` chunk extensions start at byte 18 (0-based).

* **Bug Fix:** Files in WAVE_FORMAT_EXTENSIBLE format with a missing or incomplete `"fmt "` chunk extension can no longer be opened using `Reader.new`.

    Previously, a `Reader` instance could be constructed for a file like this, but the relevant fields on the object returned by `Reader#native_format` would contain `nil` or `""` values for these fields, and no sample data could be read from the file. Since files like this are missing required fields that don't have sensible default values, it seems like it shouldn't be possible to create a `Reader` instance from them. After this fix, attempting to do so will cause `InvalidFormatError` to be raised.

# Previous Release: v1.1.1

Released on December 29, 2019, this version contains this change:

* Removes `warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call` output when reading a file with a `smpl` chunk using Ruby 2.7.0. (And presumably, higher Ruby versions as well, but Ruby 2.7.0 is the most recent Ruby version at the time of this release).

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

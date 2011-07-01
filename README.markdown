A pure Ruby gem for reading and writing sound files in Wave format (*.wav).

# Current Status (as of July 1, 2011)

The most recent release is v0.3.0. Work is in progress on the trunk on v0.4.0, which is effectively a rewrite. It will not be backward compatible with the previous API (and in general, this should be the expectation until version 1.0).

All of the main pieces are in place for v0.4.0, and the API is largely complete. Although there will still probably be changes on the edges, the core API should be in place.

Current work is primarily focused on stabilization, testing with different wave files, and adding documentation.


# What's Coming in v0.4.0?

As discovered from using this gem in projects like [BEATS](http://beatsdrummachine.com), the API for previous versions is fundamentally flawed. It requires the entire wave file to be loaded into memory, and all operations (such as changing the bits per sample) occur on the entire wave file at once. This is terrible for performance for anything bigger than a short file. The old API also doesn't support incrementally appending sample data to a file. This requires client programs to use giant arrays to store the entire sample data, which is again terrible for performance, and places a practical limit on what this gem can be used for.

Starting in v0.4.0, the API will be buffer based, instead of load-everything-into-memory-at-once based. From the experience of writing some example programs using it, this is a huge improvement.

The new API is better for more than just performance reasons. For example, it's now really simple to read data out of a file in a format other than it's internal format. For example, if you are working with several files and need them to all be in the same format, it's easy to do that. Another nicety is automatic file management just like the File object. For example, it's easy to continually read the sample data from a file, passing each buffer to a block, and have the file automatically close when there is no more left.

Note that the ability to convert sample data to floating point (i.e. values between -1.0 and 1.0) won't be present in v0.4.0 to keep the scope in check. However, I plan to add this back in a future version.


# Usage Instructions for v0.3.0

The notes below cover v0.3.0; v0.4.0 will be different.

# Installation

First, install the WaveFile gem from rubygems.org:

    gem install wavefile

...and include it in your Ruby program:

    require 'wavefile'

# Usage

To open a wave file and get the raw sample data:

    w = WaveFile.open("myfile.wav")
    samples = w.sample_data

Sample data is stored in an array. For mono files, each sample is a single number. For stereo files, each sample is represented by an array containing a value for the left and right channel.

    # Mono example
    [0, 128, 255, 128]
    
    # Stereo example
    [[0, 255], [128, 128], [255, 0], [128, 128]]

You can also get the sample data in a normalized form, with each sample between -1.0 and 1.0:

    normalized_samples = w.normalized_sample_data

You can get basic metadata:

    w.num_channels      # 1 for mono, 2 for stereo
    w.mono?             # Alias for num_channels == 1
    w.stereo?           # Alias for num_channels == 2
    w.sample_rate       # 11025, 22050, 44100, etc.
    w.bits_per_sample   # 8 or 16
    w.duration          # Example: {:hours => 0, :minutes => 3, :seconds => 12, :milliseconds => 345 }

You can view all of the metadata at once using the `inspect()` method. It returns a multi-line string:

    w.inspect()
	
	# Example result:
	#   Channels:        2
	#   Sample rate:     44100
	#   Bits per sample: 16
	#   Block align:     4
	#   Byte rate:       176400
	#   Sample count:    498070
	#   Duration:        0h:0m:11s:294ms

You can use setter methods to convert a file to a different format. For example, you can convert a mono file to stereo, or down-sample a 16-bit file to 8-bit.

	w.num_channels = 2
	w.num_channels = :stereo   // Equivalent to line above
	w.sample_rate = 22050
	w.bits_per_sample = 16	

Changes are not saved to disk until you call the `save()` method.

	w.save("myfile.wav")

To create and save a new wave file:

    w = WaveFile.new(1, 44100, 16)  # num_channels,
                                    # sample_rate,
                                    # bits_per_sample
    w.sample_data = <array of samples goes here>
    w.save("myfile.wav")

When calling the `sample_data=()` method, the passed in array can contain either raw samples or normalized samples. If the first item in the array is a Float, the entire array is assumed to be normalized. Normalized samples are automatically converted into raw samples when saving.

You can reverse a file with the `reverse()` method:

	w = WaveFile.open("myfile.wav")
	w.reverse()
	w.save("myfile_reversed.wav")

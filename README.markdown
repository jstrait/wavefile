A Ruby gem for reading and writing wave files (*.wav).

# Installation

First, install the WaveFile gem...

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

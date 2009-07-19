A Ruby gem for reading and writing wave files (*.wav).

# Installation

First, install the WaveFile gem...

    sudo gem install jstrait-wavefile -s http://gems.github.com

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
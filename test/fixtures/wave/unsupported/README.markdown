The files in this folder are wave files that do not violate the wave file spec, but can not be read by the WaveFile gem.

* **unsupported_audio_format.wav** - The audio format defined in the format chunk is 6, or A-law. While a valid format, this gem does not support it.
* **unsupported_bits_per_sample.wav** - The bits per sample is 20, which is not supported by this gem.
* **bad_channel_count.wav** - The channel count defined in the format chunk is 0.
* **bad_sample_rate.wav** - The sample rate defined in the format chunk is 0.

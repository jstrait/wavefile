require 'wavefile/buffer'
require 'wavefile/duration'
require 'wavefile/format'
require 'wavefile/info'
require 'wavefile/reader'
require 'wavefile/writer'

module WaveFile
  VERSION = "0.4.0"

  WAVEFILE_FORMAT_CODE = "WAVE"
  FORMAT_CHUNK_BYTE_LENGTH = {:pcm => 16}
  FORMAT_CODES = {:pcm => 1}
  CHUNK_IDS = {:riff         => "RIFF",
               :format       => "fmt ",
               :data         => "data",
               :fact         => "fact",
               :silence      => "slnt",
               :cue          => "cue ",
               :playlist     => "plst",
               :list         => "list",
               :label        => "labl",
               :labeled_text => "ltxt",
               :note         => "note",
               :sample       => "smpl",
               :instrument   => "inst" }

  PACK_CODES = {:pcm => {8 => "C*", 16 => "s*", 32 => "l*"}}

  UNSIGNED_INT_16 = "v"
  UNSIGNED_INT_32 = "V"
end


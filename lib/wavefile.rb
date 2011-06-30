require 'wavefile/buffer'
require 'wavefile/format'
require 'wavefile/info'
require 'wavefile/reader'
require 'wavefile/writer'

module WaveFile
  VERSION = "0.4.0alpha"

  WAVEFILE_FORMAT_CODE = "WAVE"
  FORMAT_CHUNK_BYTE_LENGTH = 16
  PCM = 1
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
  PACK_CODES = {8 => "C*", 16 => "s*", 32 => "V*"}
end


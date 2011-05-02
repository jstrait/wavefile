require 'lib/buffer.rb'
require 'lib/format.rb'
require 'lib/info.rb'
require 'lib/reader.rb'
require 'lib/writer.rb'

module WaveFile
  VERSION = "0.4.0a"

  WAVEFILE_FORMAT_CODE = "WAVE"
  FORMAT_CHUNK_BYTE_LENGTH = 16
  PCM = 1
  HEADER_BYTE_LENGTH = 36
  CHUNK_IDS = {:header       => "RIFF",
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


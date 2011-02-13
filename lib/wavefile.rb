module WaveFile
  VERSION = "0.4.0a"

  FORMAT = "WAVE"
  SUB_CHUNK1_SIZE = 16
  PCM = 1
  DATA_CHUNK_ID = "data"
  HEADER_SIZE = 36
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


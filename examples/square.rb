$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'wavefile'
include WaveFile

BUFFER_SIZE = 4096

Writer.new("square.wav", Format.new(1, 16, 44100)) do |writer|
  samples = (([16000] * 32) + ([-16000] * 32)) * (BUFFER_SIZE / 64)
  100.times do
    buffer = Buffer.new(samples, writer.format)
    writer.write(buffer)
  end
end

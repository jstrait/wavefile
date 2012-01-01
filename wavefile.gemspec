Gem::Specification.new do |s| 
  s.name = "wavefile"
  s.version = "0.4.0"
  s.author = "Joel Strait"
  s.email = "joel dot strait at Google's popular web mail service"
  s.homepage = "http://www.joelstrait.com/"
  s.platform = Gem::Platform::RUBY
  s.summary = "A class for reading and writing Wave sound files (*.wav)"
  s.files = ["LICENSE", "README.markdown", "Rakefile"] + Dir["lib/**/*.rb"] + Dir["test/**/*"]
  s.require_path = "lib"
end

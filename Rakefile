require 'rake/testtask'
require 'rdoc/task'
#$:.push File.expand_path("../tools", __FILE__)

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include("README.markdown", "lib")
  rdoc.main = "README.markdown"
  rdoc.title = "WaveFile Gem - Read/Write *.wav Files with Ruby"
  rdoc.markup = "tomdoc"
  rdoc.rdoc_dir = "doc"
end

namespace :test do
  task :create_fixtures do
    fixtures = Dir.glob("tools/*.yml")

    fixtures.each do |fixture|
      basename = File.basename(fixture, ".yml")
      `ruby tools/fixture_writer.rb #{fixture} tools/#{basename}.wav`
    end
  end
end

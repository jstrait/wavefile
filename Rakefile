require 'rake/testtask'
require 'rdoc/task'

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

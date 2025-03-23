$LOAD_PATH.unshift("../coradoc/lib")

require "coradoc"
require "coradoc/input/html"

require "pp"
require "stringio"

rt = ARGV[0]

rt_path = if rt == "rice-2023"
            "../mn-samples-iso/sources/international-standard/rice-2023/"
          elsif rt.to_s.include? "samples"
            "../mn-samples-iso/sources/"
          else
            "./spec/fixtures/"
          end

if !Dir.exist?(rt_path)
  puts "pleas set path to rice-2023"
  exit
end

adoc_files = Dir.glob("#{rt_path}**/*adoc")

adoc_files.each do |file_path|
  puts file_path
  file_path_ast = "#{file_path}.ast"
  file_path_rt = "#{file_path}.roundtrip"
  file_path_diff = "#{file_path}.roundtrip.diff"
  FileUtils.rm(file_path_rt) if File.exist?(file_path_rt)
  FileUtils.rm(file_path_diff) if File.exist?(file_path_diff)
  # begin
  adoc_file = File.open(file_path).read
  next if adoc_file.empty?

  puts "parsing..."
  ast = Coradoc::Parser::Base.new.parse(adoc_file)
  sio = StringIO.new
  PP.pp(ast, sio)
  ast_string = sio.string
  File.open(file_path_ast, "w") { |f| f.write(ast_string) }
  puts "transforming..."
  doc = Coradoc::Transformer.transform(ast[:document])
  puts "generating..."
  generated_adoc = Coradoc::Generator.gen_adoc(doc)
  cleaned_adoc = Coradoc::Input::HTML.cleaner.tidy(generated_adoc)
  File.open("#{file_path}.roundtrip", "w") { |f| f.write(cleaned_adoc) }
  `diff -B #{file_path} #{file_path}.roundtrip > #{file_path}.roundtrip.diff`
  # rescue
  # puts "unsuccessful..."
  # end
end

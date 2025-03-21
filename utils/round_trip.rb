$LOAD_PATH.unshift("../coradoc/lib")

require "coradoc"
require "coradoc/input/html"

rice_path = "../mn-samples-iso/sources/international-standard/rice-2023/"

if !Dir.exist?(rice_path)
  puts "pleas set path to rice-2023"
  exit
end

adoc_files = Dir.glob("#{rice_path}**/*adoc")

adoc_files.each do |file_path|
  puts file_path
  file_path_rt = "#{file_path}.roundtrip"
  file_path_diff = "#{file_path}.roundtrip.diff"
  FileUtils.rm(file_path_rt) if File.exist?(file_path_rt)
  FileUtils.rm(file_path_diff) if File.exist?(file_path_diff)
  # begin
  adoc_file = File.open(file_path).read
  next if adoc_file.size == 0

  puts "parsing..."
  ast = Coradoc::Parser::Base.new.parse(adoc_file)
  puts "transforming..."
  doc = Coradoc::Transformer.transform(ast[:document])
  puts "generating..."
  generated_adoc = Coradoc::Generator.gen_adoc(doc)
  cleaned_adoc = Coradoc::Input::Html.cleaner.tidy(generated_adoc)
  File.open("#{file_path}.roundtrip", "w") { |f| f.write(cleaned_adoc) }
  `diff -BNaur #{file_path} #{file_path}.roundtrip > #{file_path}.roundtrip.diff`
  # rescue
  # puts "unsuccessful..."
  # end
end

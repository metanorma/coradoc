$LOAD_PATH.unshift("../coradoc/lib")
require "coradoc"
require "pp"

def pretty_print_obj(obj)
  sio = StringIO.new
  PP.pp(obj, sio, 69)
  puts sio.string
end

def print_parsed(str)
  parse = Coradoc::Parser::Base.new.parse(str)
  puts str
  puts ""
  pretty_print_obj parse[:document]
  puts ""
  doc = Coradoc::Transformer.transform(parse[:document])
  pp doc
  puts Coradoc::Generator.gen_adoc(doc)
end

content = <<~END
  [a='quoted named']
  ****
  block
  ****
END

print_parsed(content)

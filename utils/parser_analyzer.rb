require "rubocop"

def ast_from(string)
  RuboCop::ProcessedSource.new(string, RUBY_VERSION.to_f).ast
end

def is_def?(arr)
  if Array === arr
    if arr[0] == :def
      $defs << arr
    else
      arr.each do |e|
        is_def?(e)
      end
    end
  end
end

path = "lib/coradoc/parser/asciidoc/"
class_files = Dir.entries(path).select{|x| File.file?(path+x)}

$all_defs = {}

class_files.each do |cf|
  a = ast_from(File.open(path+cf).read)
  next if a.nil?
  sexp = a.to_sexp_array
  $defs = []
  is_def?(sexp)
  $all_defs[cf] = $defs
end;

relevant_names = $all_defs.map{|fn, defs| defs.map{|d| d[1]}}.flatten;

require 'graphviz'

g = GraphViz.new( :G, :type => :digraph );

g[:fontsize] = 8
g[:rankdir] = "LR"
g[:overlap] = false
g[:splines] = false

nodes = {}

$all_defs.each do |file_name, defs|

  defs.each do |ast_def|
    calls = ast_def[2..-1].flatten & relevant_names
    node_name = ast_def[1]
    nodes[node_name] = g.add_nodes( "#{node_name}\n#{file_name}" )
  end
end;

$all_defs.each do |file_name, defs|
  defs.each do |ast_def|
    calls = ast_def[2..-1].flatten & relevant_names
    node_name = ast_def[1]
    calls.each do |cl|
      w = g.add_edges(nodes[node_name], nodes[cl])
      w[:weight] = 1.5
    end
  end
end;

g.output( :png => "utils/parser_graph.png_#{Time.now.to_i}" );

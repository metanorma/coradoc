#!/bin/sh
# usage: bench/run.sh CORPUS OUT.json [CHUNKS]  (run inside a bundle env for the checkout under test)
# Runs the benchmark in CHUNKS sequential processes (bounded memory) and merges the results.
dir=$1; out=$2; n=${3:-8}
i=0
while [ $i -lt $n ]; do
  CHUNK=$i/$n ruby "$(dirname "$0")/plateau_corpus.rb" "$dir" "$out.$i" >/dev/null 2>&1 || echo "chunk $i failed" >&2
  i=$((i+1))
done
ruby -rjson -e 'o=ARGV.shift; fs={}; r=nil; ARGV.each{|f| j=JSON.parse(File.read(f)); r=j["ruby"]; fs.merge!(j["files"]); File.delete(f)}; File.write(o, JSON.pretty_generate("ruby"=>r,"files"=>fs)); puts "#{fs.size} files, #{fs.count{|_,v| v["error"]}} errors, parse #{fs.values.sum{|v| (v["s1"]||0)+(v["s2"]||0)+(v["core_t"]||0)}.round(2)}s"' "$out" "$out".*

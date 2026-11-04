# frozen_string_literal: true

# ruby bench/compare.rb OLD1.json OLD2.json OLD3.json -- NEW1.json NEW2.json NEW3.json
# Median-of-runs timing per stage plus per-file output identity.
require 'json'

old, new = ARGV.join(' ').split(' -- ').map { |s| s.split.map { |f| JSON.parse(File.read(f)) } }
med = ->(a) { a.sort[a.size / 2] }
ofiles = old.first['files']
nfiles = new.first['files']
common = ofiles.keys & nfiles.keys
total = ->(runs, k) { med.call(runs.map { |r| common.sum { |f| r['files'][f][k] || 0 } }) }
puts "ruby #{old.first['ruby']}; files #{ofiles.size}/#{nfiles.size}; errors old=#{ofiles.count { |_, v| v['error'] }} new=#{nfiles.count { |_, v| v['error'] }}"
tot = { 'old' => 0, 'new' => 0 }
%w[s1 s2 core_t].each do |k|
  o = total.call(old, k)
  n = total.call(new, k)
  tot['old'] += o
  tot['new'] += n
  puts format('%<k>-7s old %<o>.3fs new %<n>.3fs (new/old %<r>.3f)', k: k, o: o, n: n, r: n / o)
end
puts format('total   old %<o>.3fs new %<n>.3fs  files/s old %<of>.1f new %<nf>.1f',
            o: tot['old'], n: tot['new'], of: common.size / tot['old'], nf: common.size / tot['new'])
%w[ast model core core_norm error].each do |k|
  d = common.reject { |f| ofiles[f][k] == nfiles[f][k] }
  puts "#{k}: #{common.size - d.size}/#{common.size} identical; differing: #{d.first(20).join(', ')}"
end

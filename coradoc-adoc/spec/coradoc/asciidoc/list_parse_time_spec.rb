# frozen_string_literal: true

require 'spec_helper'

# line_not_text used the full list rules as its guard, so every
# continuation line re-parsed the rest of the list: parse time doubled with
# each item (a 20-item list took over a minute; coradoc#308). The guard now
# looks one line deep. These run in a child process under a hard limit
# because the native parser cannot be interrupted from Ruby.
RSpec.describe 'List parse time (#308)' do
  def parsed_within?(text, seconds)
    pid = fork do
      Coradoc::AsciiDoc::Parser::Base.new.parse(text)
      exit!(0)
    end
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    loop do
      return Process.last_status.success? if Process.waitpid(pid, Process::WNOHANG)

      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        Process.kill('KILL', pid)
        Process.wait(pid)
        return false
      end
      sleep 0.05
    end
  end

  {
    'unordered' => ->(i) { "* item #{i}" },
    'ordered' => ->(i) { ". item #{i}" },
    'definition' => ->(i) { "term#{i}:: definition #{i}" },
    'term-only definition' => ->(i) { "term#{i}::" }
  }.each do |kind, line|
    it "parses a 60-item #{kind} list in bounded time" do
      text = "intro\n\n#{(1..60).map { |i| line.call(i) }.join("\n")}\n"
      expect(parsed_within?(text, 20)).to be(true)
    end
  end

  it 'parses a definition list inside an example block in bounded time' do
    items = (1..60).map { |i| "requirement:: /req/gm/#{i}" }.join("\n")
    expect(parsed_within?("====\n[%metadata]\n#{items}\n====\n", 20)).to be(true)
  end

  it 'still stops a definition body at the next definition' do
    ast = Coradoc::AsciiDoc::Parser::Base.new.parse("a:: one\nb:: two\n")
    items = ast[:document].first[:list][:definition_list]
    expect(items.size).to eq(2)
  end
end

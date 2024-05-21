require "simplecov"

SimpleCov.profiles.define "gem" do
  add_filter "/spec/"
  add_filter "/autotest/"
  add_group "Libraries", "/lib/"
end
SimpleCov.start "gem"

require "coradoc/reverse_adoc"
require "coradoc/reverse_adoc/html_converter"
require "word-to-markdown"

Dir[File.join("spec", "reverse_adoc", "support", "**", "*.rb")]
  .each { |f| require File.join(".", f) }

RSpec.configure do |config|
  config.after(:each) do
    Coradoc::ReverseAdoc.instance_variable_set(:@config, nil)
  end
end

def node_for(html)
  Nokogiri::HTML.parse(html).root.child.child
end

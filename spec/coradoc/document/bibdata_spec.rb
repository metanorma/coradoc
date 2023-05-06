require "spec_helper"

RSpec.describe Coradoc::Document::Bibdata do
  describe ".initialize" do
    it "initializes and exposes bibdata" do
      data = [Coradoc::Document::Attribute.new("name", "value")]
      bibdata = Coradoc::Document::Bibdata.new(data)

      expect(bibdata.data).to eq(data)
    end
  end
end

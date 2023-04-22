require "spec_helper"

RSpec.describe Coradoc::Document::Revision do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      number = 1.0
      remark = "Version comment note"
      revision_date = "2023-02-23"

      revision = Coradoc::Document::Revision.new(
        number, date: revision_date, remark: remark
      )

      expect(revision.number).to eq(number)
      expect(revision.remark).to eq(remark)
      expect(revision.date).to eq(revision_date)
    end
  end
end

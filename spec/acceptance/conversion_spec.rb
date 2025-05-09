# frozen_string_literal: true

RSpec.describe "Conversion" do
  let(:output) { StringIO.new }

  before do
    Coradoc::Converter.call(
      input,
      output,
      input_processor: input_format,
      output_processor: output_format,
    )
  end

  describe "from html to asciidoc" do
    let(:input_format) { :html }
    let(:output_format) { :adoc }

    describe "video tags" do
      subject(:output_string) { output.string }

      let(:input) { StringIO.new("<video src='example.mp4' />") }

      it { is_expected.to eq "video::example.mp4[]" }
    end
  end
end

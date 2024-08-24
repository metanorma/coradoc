require "spec_helper"
require "coradoc/cli"

RSpec.describe Coradoc::CLI do
  let(:cli) { described_class.new }
  let(:input_file) { "input.html" }
  let(:output_file) { "output.adoc" }
  let(:input_format) { :html }
  let(:output_format) { :adoc }

  describe "#convert" do
    let(:mock_converter) { double("Coradoc::Converter") }

    before do
      allow(Coradoc::Converter).to receive(:call).and_return(mock_converter)
    end

    context "when called with valid input and output" do
      it "calls the Converter with the correct arguments" do
        expect(Coradoc::Converter).to receive(:call).with(
          input_file,
          output_file,
          input_options: {
            external_images: nil,
            unknown_tags: "pass_through",
            mathml2asciimath: nil,
            track_time: nil,
            split_sections: 0,
          },
          input_processor: nil,
          output_options: {},
          output_processor: nil,
        )

        cli.invoke(:convert, [input_file], output: output_file)
      end
    end

    context "when input file is not provided" do
      it "warns the user about the missing input file" do
        allow(Coradoc::Converter).to receive(:call).and_raise(Coradoc::Converter::NoInputPathError.new("Input file missing"))

        expect do
          cli.invoke(:convert, [], output_format: output_format)
        end.to output(/You must provide INPUT file as a file for this optionset./).to_stderr
      end
    end

    context "when output file is not provided" do
      it "warns the user about the missing output file" do
        allow(Coradoc::Converter).to receive(:call).and_raise(Coradoc::Converter::NoOutputPathError.new("Output file missing"))

        expect do
          cli.invoke(:convert,
                     [input_file], output_format: output_format)
        end.to output(/You must provide OUTPUT file as a file for this optionset./).to_stderr
      end
    end

    context "when no processor is found" do
      it "warns the user about the missing processor" do
        allow(Coradoc::Converter).to receive(:call).and_raise(Coradoc::Converter::NoProcessorError.new("No processor found"))

        expect do
          cli.invoke(:convert, [input_file],
                     output: output_file, output_format: :asdf)
        end.to output(/No processor found for given input\/output./).to_stderr
      end
    end

    context "when additional Ruby files are required" do
      it "requires the specified files" do
        expect(Kernel).to receive(:require).with("some_file")
        expect(Kernel).to receive(:require).with("another_file")

        cli.invoke(:convert, [input_file],
                   require: ["some_file", "another_file"],
                   output_format: output_format)
      end
    end

    context "when options are provided" do
      it "passes the options to the converter" do
        expect(Coradoc::Converter).to receive(:call).with(
          input_file,
          output_file,
          input_options: {
            external_images: true,
            unknown_tags: "drop",
            mathml2asciimath: true,
            track_time: true,
            split_sections: 2,
          },
          input_processor: input_format,
          output_options: {},
          output_processor: output_format,
        )

        cli.invoke(:convert, [input_file], {
                     output: output_file,
                     input_format: input_format,
                     output_format: output_format,
                     external_images: true,
                     unknown_tags: "drop",
                     mathml2asciimath: true,
                     track_time: true,
                     split_sections: 2,
                   })
      end
    end
  end
end

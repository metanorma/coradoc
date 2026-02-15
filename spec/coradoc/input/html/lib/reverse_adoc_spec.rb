require "spec_helper"

describe Coradoc::Input::Html do
  let(:input)    { File.read("spec/coradoc/input/html/assets/minimum.html") }
  let(:document) { Nokogiri::HTML(input) }

  it "parses nokogiri documents" do
    expect { described_class.convert(document) }.not_to raise_error
  end

  it "parses nokogiri elements" do
    expect { described_class.convert(document.root) }.not_to raise_error
  end

  it "parses string input" do
    expect { described_class.convert(input) }.not_to raise_error
  end

  it "behaves in a sane way when root element is nil" do
    expect(described_class.convert(nil)).to eq ""
  end

  describe "#config" do
    it "stores a given configuration option" do
      described_class.config.tag_border = true
      expect(described_class.config.tag_border).to be true
    end

    it "can be used as a block configurator as well" do
      described_class.config do |config|
        expect(config.tag_border).to eq " "
        config.tag_border = true
      end
      expect(described_class.config.tag_border).to be true
    end
  end

  shared_examples "converting source with external images included" do |result|
    let(:temp_dir) do
      Pathname.new(described_class.config.destination).dirname
    end
    let(:images_folder) { File.join(temp_dir, "images") }

    before do
      described_class.config.destination = File.join(Dir.mktmpdir,
                                                     "output.html")
      described_class.config.sourcedir = Dir.mktmpdir
      described_class.config.external_images = true
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "Creates local files from external URI" do
      expect { convert }
        .to(change do
          Dir["#{images_folder}/*"]
            .map { |entry| File.basename(entry) }
            .sort
        end.from([]).to(result))
    end
  end

  # TODO: fix github actions integration with libreoffice, currently it hangs
  # when trying to use soffice binary
  unless Gem::Platform.local.os == "darwin" && !ENV["GITHUB_ACTION"].nil?
    context "when docx file input" do
      subject(:convert) do
        described_class.convert(
          described_class.cleaner.preprocess_word_html(input.document.html),
          WordToMarkdown::REVERSE_MARKDOWN_OPTIONS,
        )
      end

      let(:input) do
        WordToMarkdown.new("spec/coradoc/input/html/assets/external_images.docx",
                           described_class.config.sourcedir)
      end

      it_behaves_like "converting source with external images included",
                      ["001.gif", "002.gif"]
    end
  end

  context "when html file input" do
    subject(:convert) { described_class.convert(input) }

    let(:input) do
      File.read("spec/coradoc/input/html/assets/external_images.html")
    end

    it_behaves_like "converting source with external images included",
                    ["001.gif"]
  end

  context "when html file input with internal images" do
    subject(:convert) { described_class.convert(input) }

    let(:input) do
      File.read("spec/coradoc/input/html/assets/internal_images.html")
    end

    it_behaves_like "converting source with external images included",
                    ["001.png", "002.jpeg", "003.webp", "004.avif", "005.gif"]
  end
end

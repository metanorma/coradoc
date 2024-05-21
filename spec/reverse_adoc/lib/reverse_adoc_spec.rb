require "spec_helper"

describe Coradoc::ReverseAdoc do
  let(:input)    { File.read("spec/reverse_adoc/assets/minimum.html") }
  let(:document) { Nokogiri::HTML(input) }

  it "parses nokogiri documents" do
    expect { Coradoc::ReverseAdoc.convert(document) }.not_to raise_error
  end

  it "parses nokogiri elements" do
    expect { Coradoc::ReverseAdoc.convert(document.root) }.not_to raise_error
  end

  it "parses string input" do
    expect { Coradoc::ReverseAdoc.convert(input) }.not_to raise_error
  end

  it "behaves in a sane way when root element is nil" do
    expect(Coradoc::ReverseAdoc.convert(nil)).to eq ""
  end

  describe "#config" do
    it "stores a given configuration option" do
      Coradoc::ReverseAdoc.config.tag_border = true
      expect(Coradoc::ReverseAdoc.config.tag_border).to eq true
    end

    it "can be used as a block configurator as well" do
      Coradoc::ReverseAdoc.config do |config|
        expect(config.tag_border).to eq " "
        config.tag_border = true
      end
      expect(Coradoc::ReverseAdoc.config.tag_border).to eq true
    end
  end

  shared_examples "converting source with external images included" do |result|
    let(:temp_dir) do
      Pathname.new(Coradoc::ReverseAdoc.config.destination).dirname
    end
    let(:images_folder) { File.join(temp_dir, "images") }

    before do
      Coradoc::ReverseAdoc.config.destination = File.join(Dir.mktmpdir,
                                                 "output.html")
      Coradoc::ReverseAdoc.config.sourcedir = Dir.mktmpdir
      Coradoc::ReverseAdoc.config.external_images = true
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
        Coradoc::ReverseAdoc.convert(
          Coradoc::ReverseAdoc.cleaner.preprocess_word_html(input.document.html),
          WordToMarkdown::REVERSE_MARKDOWN_OPTIONS,
        )
      end
      let(:input) do
        WordToMarkdown.new("spec/reverse_adoc/assets/external_images.docx",
                           Coradoc::ReverseAdoc.config.sourcedir)
      end
      it_behaves_like "converting source with external images included",
                      ["001.gif", "002.gif"]
    end
  end

  context "when html file input" do
    subject(:convert) { Coradoc::ReverseAdoc.convert(input) }
    let(:input) { File.read("spec/reverse_adoc/assets/external_images.html") }
    it_behaves_like "converting source with external images included",
                    ["001.gif"]
  end

  context "when html file input with internal images" do
    subject(:convert) { Coradoc::ReverseAdoc.convert(input) }
    let(:input) { File.read("spec/reverse_adoc/assets/internal_images.html") }
    it_behaves_like "converting source with external images included",
                    ["001.png", "002.jpeg", "003.webp", "004.avif", "005.gif"]
  end
end

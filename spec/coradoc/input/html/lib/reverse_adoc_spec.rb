require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input)    { File.read("spec/coradoc/input/html/assets/minimum.html") }
  let(:document) { Nokogiri::HTML(input) }

  it "parses nokogiri documents" do
    expect { Coradoc::Input::HTML.convert(document) }.not_to raise_error
  end

  it "parses nokogiri elements" do
    expect { Coradoc::Input::HTML.convert(document.root) }.not_to raise_error
  end

  it "parses string input" do
    expect { Coradoc::Input::HTML.convert(input) }.not_to raise_error
  end

  it "behaves in a sane way when root element is nil" do
    expect(Coradoc::Input::HTML.convert(nil)).to eq ""
  end

  describe "#config" do
    it "stores a given configuration option" do
      Coradoc::Input::HTML.config.tag_border = true
      expect(Coradoc::Input::HTML.config.tag_border).to eq true
    end

    it "can be used as a block configurator as well" do
      Coradoc::Input::HTML.config do |config|
        expect(config.tag_border).to eq " "
        config.tag_border = true
      end
      expect(Coradoc::Input::HTML.config.tag_border).to eq true
    end
  end

  shared_examples "converting source with external images included" do |result|
    let(:temp_dir) do
      Pathname.new(Coradoc::Input::HTML.config.destination).dirname
    end
    let(:images_folder) { File.join(temp_dir, "images") }

    before do
      Coradoc::Input::HTML.config.destination = File.join(Dir.mktmpdir,
                                                          "output.html")
      Coradoc::Input::HTML.config.sourcedir = Dir.mktmpdir
      Coradoc::Input::HTML.config.external_images = true
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
        Coradoc::Input::HTML.convert(
          Coradoc::Input::HTML.cleaner.preprocess_word_html(input.document.html),
          WordToMarkdown::REVERSE_MARKDOWN_OPTIONS,
        )
      end
      let(:input) do
        WordToMarkdown.new("spec/coradoc/input/html/assets/external_images.docx",
                           Coradoc::Input::HTML.config.sourcedir)
      end
      it_behaves_like "converting source with external images included",
                      ["001.gif", "002.gif"]
    end
  end

  context "when html file input" do
    subject(:convert) { Coradoc::Input::HTML.convert(input) }
    let(:input) do
      File.read("spec/coradoc/input/html/assets/external_images.html")
    end
    it_behaves_like "converting source with external images included",
                    ["001.gif"]
  end

  context "when html file input with internal images" do
    subject(:convert) { Coradoc::Input::HTML.convert(input) }
    let(:input) do
      File.read("spec/coradoc/input/html/assets/internal_images.html")
    end
    it_behaves_like "converting source with external images included",
                    ["001.png", "002.jpeg", "003.webp", "004.avif", "005.gif"]
  end
end

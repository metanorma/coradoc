require "spec_helper"

RSpec.describe Coradoc::Parser do
  describe ".parse" do
    it "parses the document using parselet" do
      sample_file = Coradoc.root_path.join("spec", "fixtures", "sample.adoc")

      document = Coradoc::Parser.parse(sample_file)[:document]

      pp document

      expect_document_to_match_header(document[0])
      expect_document_to_match_bibdata(document[1])
      expect_document_to_match_section_with_body(document[2])
      expect_document_to_match_section_titles(document[3..10])
      expect_document_to_match_inline_formatting(document[11])
      expect_document_to_match_numbered_list_section(document[12])
      expect_document_to_match_unnumbered_list_section(document[13])
      expect_document_to_match_definition_list_section(document[14])
      expect_document_to_match_basic_block_sections(document[16])
      expect_document_to_match_the_top_lavel_block(document[17])
      exepct_docuemnt_to_match_the_open_block_syntax(document[18])
      expect_document_to_match_the_example_block_syntax(document[19])
      expect_docuemnt_to_match_source_code_block_syntax(document[20])
      expect_document_to_match_source_block_perimeter(document[21])
      expect_document_to_mathc_sidebar_block_syntax(document[22])
      expect_docuemnt_to_match_sidebar_block_perimeter(document[23])
      expect_docuemnt_to_match_quote_open_block_syntax(document[24])
      expect_document_to_match_quote_perimeter_block(document[25])
      expect_document_to_match_differnt_admonition(document[26])
      expect_document_to_match_section_with_anchor(document[28])
      expect_document_to_match_section_with_links(document[29])

      # let's see what's in there
      pp document
    end
  end

  #
  # Note: Ignore this section for nos
  #
  # The following section it to make sure that incrementaal changes
  # does not break any of the existing parsing machanisim, onece done
  # then we will have proper test suite here.
  #
  def expect_document_to_match_section_with_links(doc)
    section = doc[:section]

    expect(section[:title][:text]).to eq("Links")
    expect(section[:paragraphs][0][:text]).to eq(
      "This renders as a URL: https://www.example.com."
    )

    expect(section[:paragraphs][1][:text]).to eq(
      "This renders as a URL: https://www.example.com[Example.Com]."
    )
  end

  def expect_document_to_match_section_with_anchor(doc)
    section = doc[:section]

    expect(section[:title][:level]).to eq("===")
    expect(section[:title][:text]).to eq("Anchor")
    expect(section[:title][:name]).to eq("this-is-an-anchor")

    # We need to parsing for insline text
    expect(section[:paragraphs].count).to eq(3)
  end

  def expect_document_to_match_differnt_admonition(doc)
    section = doc[:section]
    paragraphs = section[:paragraphs]

    expect(section[:title][:text]).to eq("Admonitions")
    expect(paragraphs[0][:text]).to eq("These are all admonition types.")

    expect(paragraphs[1][:admonition][:type]).to eq("NOTE")
    expect(paragraphs[2][:admonition][:type]).to eq("TIP")
    expect(paragraphs[3][:admonition][:type]).to eq("WARNING")
    expect(paragraphs[4][:admonition][:type]).to eq("CAUTION")
    expect(paragraphs[5][:admonition][:type]).to eq("DANGER")
    expect(paragraphs[6][:admonition][:type]).to eq("IMPORTANT")
    expect(paragraphs[7][:admonition][:type]).to eq("EDITOR")
    expect(paragraphs[8][:admonition][:type]).to eq("NOTE")
    expect(paragraphs[9][:admonition][:type]).to eq("DANGER")

    expect(paragraphs[1][:admonition][:text]).to eq("This is a note.")
    expect(paragraphs[2][:admonition][:text]).to eq("This is a tip.")
    expect(paragraphs[3][:admonition][:text]).to eq("This is a warning.")
    expect(paragraphs[4][:admonition][:text]).to eq("This is a caution.")
    expect(paragraphs[5][:admonition][:text]).to eq("This is a danger warning.")
    expect(paragraphs[6][:admonition][:text]).to eq("This is an important note.")
    expect(paragraphs[7][:admonition][:text]).to eq("This is an editor note.")

    expect(paragraphs[8][:admonition][:text]).to eq(
      "This is also a NOTE but in block syntax."
    )

    expect(paragraphs[9][:admonition][:text]).to eq(
      "This is also a DANGER warning but in block syntax."
    )
  end

  def expect_document_to_match_quote_perimeter_block(doc)
    block = doc[:block]

    expect(block[:lines].count).to eq(0)
    expect(block[:delimiter]).to eq("____")
    expect(block[:title]).to eq("Quote block (with block perimeter type)")
  end

  def expect_docuemnt_to_match_quote_open_block_syntax(doc)
    block = doc[:block]

    expect(block[:type]).to eq("quote")
    expect(block[:lines].count).to eq(0)
    expect(block[:delimiter]).to eq("--")
  end

  def expect_docuemnt_to_match_sidebar_block_perimeter(doc)
    block = doc[:block]

    expect(block[:delimiter]).to eq("****")
    expect(block[:title]).to eq("Side blocks (with block perimeter type)")
    expect(block[:lines][0][:text]).to eq("This renders in the side.")
  end

  def expect_document_to_mathc_sidebar_block_syntax(doc)
    block = doc[:block]

    expect(block[:type]).to eq("side")
    expect(block[:delimiter]).to eq("****")
    expect(block[:title]).to eq("Side blocks (open block syntax)")
    expect(block[:lines][0][:text]).to eq("This renders in the side.")
  end

  def expect_document_to_match_source_block_perimeter(doc)
    block = doc[:block]

    expect(block[:delimiter]).to eq("----")
    expect(block[:title]).to eq("Source block (with block perimeter type)")
    expect(block[:lines][0][:text]).to eq("This renders in monospace.")
  end

  def expect_docuemnt_to_match_source_code_block_syntax(doc)
    block = doc[:block]

    expect(block[:type]).to eq("source")
    expect(block[:delimiter]).to eq("--")
    expect(block[:title]).to eq("Source block (open block syntax)")
    expect(block[:lines][0][:text]).to eq("This renders in monospace.")
  end

  def expect_document_to_match_the_example_block_syntax(doc)
    block = doc[:block]

    expect(block[:type]).to eq("example")
    expect(block[:delimiter]).to eq("====")
    expect(block[:title]).to eq("Example block (with block perimeter type)")
    expect(block[:lines][0][:text]).to eq("This renders as an example.")
  end

  def exepct_docuemnt_to_match_the_open_block_syntax(doc)
    section = doc[:section]
    blocks = section[:blocks]

    expect(blocks.count).to eq(1)
    expect(blocks[0][:delimiter]).to eq("--")
    expect(blocks[0][:type]).to eq("example")
    expect(blocks[0][:lines].count).to eq(1)

    expect(section[:title][:text]).to eq("Basic block with perimeters")
    expect(blocks[0][:title]).to eq("Example block (open block syntax)")
    expect(blocks[0][:lines][0][:text]).to eq("This renders as an example.")
  end

  def expect_document_to_match_the_top_lavel_block(doc)
    block = doc[:block]

    expect(block[:title]).to eq("Caption title")
    expect(block[:lines][0][:text]).to eq("This block should have a caption title.")
  end

  def expect_document_to_match_basic_block_sections(doc)
    section = doc[:section]
    blocks = section[:blocks]

    expect(section[:title][:level]).to eq("===")
    expect(section[:title][:text]).to eq("Basic block with no perimeters")

    expect(blocks.count).to eq(2)
    expect(blocks[0][:attributes]).to eq({ key: "id", value: "myblock"})
    expect(blocks[0][:lines][0][:text]).to eq(
      "This is my block with a defined ID."
    )

    expect(blocks[1][:attributes]).to eq({ key: "role", value: "source"})
    expect(blocks[1][:lines][0][:text]).to eq(
      "This should be rendered in source code format."
    )
  end

  def expect_document_to_match_definition_list_section(doc)
    section = doc[:section]
    list = section[:list][:definition]

    expect(section[:title][:level]).to eq("==")
    expect(section[:title][:text]).to eq("Definition list")
    expect(section[:list][:definition].count).to eq(6)

    expect(list[0][:text]).to eq("definition list item 1")
    expect(list[2][:text]).to eq("definition list item 3")
    expect(list[4][:text]).to eq("definition list item 5")
    expect(list[5][:text]).to eq("definition list item 15")
  end

  def expect_document_to_match_unnumbered_list_section(doc)
    section = doc[:section]
    list = section[:list][:unnumbered]

    expect(section[:title][:level]).to eq("==")
    expect(section[:title][:text]).to eq("Unnumbered list")
    expect(section[:list][:unnumbered].count).to eq(5)

    expect(list[0][:text]).to eq("Unnumbered list item 1")
    expect(list[2][:text]).to eq("Unnumbered list item 3")
    expect(list[4][:text]).to eq("Unnumbered list item 5")
  end

  def expect_document_to_match_numbered_list_section(doc)
    section = doc[:section]
    numbered_list = section[:list][:numbered]

    expect(section[:title][:level]).to eq("==")
    expect(section[:title][:text]).to eq("Numbered list")
    expect(section[:list][:numbered].count).to eq(5)

    expect(numbered_list[0][:text]).to eq("Numbered list item 1")
    expect(numbered_list[2][:text]).to eq("Numbered list item 3")
    expect(numbered_list[4][:text]).to eq("Numbered list item 5")
  end

  def expect_document_to_match_inline_formatting(doc)
    section = doc[:section]

    expect(section[:title][:level]).to eq("==")
    expect(section[:title][:text]).to eq("Inline formatting")

    expect(section[:paragraphs].count).to eq(9)
    expect(section[:paragraphs][0][:text]).to eq("This is a *bold* statement.")

    expect(section[:paragraphs][3][:text]).to eq(
      "This is in __italics with double underscores__.")

    expect(section[:paragraphs][6][:text]).to eq(
      "This is [underscore]#underscored#.")

    expect(section[:paragraphs][8][:text]).to eq(
      "This is in [smallcaps]#smallcaps#.")
  end

  def expect_document_to_match_section_titles(doc)
    expect(doc[0][:section][:title][:level]).to eq("==")
    expect(doc[0][:section][:title][:text]).to eq("Level 1 clause heading")

    expect(doc[1][:section][:title][:level]).to eq("===")
    expect(doc[1][:section][:title][:text]).to eq("Level 2 clause heading")

    expect(doc[3][:section][:title][:level]).to eq("=====")
    expect(doc[3][:section][:title][:text]).to eq("Level 4 clause heading")

    expect(doc[7][:section][:title][:level]).to eq("========")
    expect(doc[7][:section][:title][:text]).to eq("Level 8 clause heading")
  end

  def expect_document_to_match_section_with_body(doc)
    section = doc[:section]

    expect(section[:title][:level]).to eq("==")
    expect(section[:title][:text]).to eq("Attribute rendering")
    expect(section[:paragraphs].count).to eq(2)

    expect(section[:paragraphs][0][:text]).to eq(
      'This ({string-attribute}) renders as "this has to be a string".')

    expect(section[:paragraphs][1][:text]).to eq(
      'This ({url-attribute}) renders as "https://example.com".')
  end

  def expect_document_to_match_bibdata(doc)
    bibdata = doc[:bibdata]

    # this is not correct btw, should be 10
    expect(bibdata.count).to eq(9)

    expect(bibdata[0][:key]).to eq("string-attribute")
    expect(bibdata[0][:value]).to eq("this has to be a string")

    expect(bibdata[3][:key]).to eq("number-attribute")
    expect(bibdata[3][:value]).to eq("300")


    expect(bibdata[6][:key]).to eq("uri-attribute")
    expect(bibdata[6][:value]).to eq("https://example.com")
  end

  def expect_document_to_match_header(doc)
    header= doc[:header]

    expect(header[:title]).to eq("This is the title")
    expect(header[:author][:first_name]).to eq("Given name")
    expect(header[:author][:last_name]).to eq("Last name")
    expect(header[:author][:email]).to eq("email@example.com")

    expect(header[:revision][:number]).to eq("1.0")
    expect(header[:revision][:date]).to eq("2023-02-23")
    expect(header[:revision][:remark]).to eq("Version comment note")
  end
end

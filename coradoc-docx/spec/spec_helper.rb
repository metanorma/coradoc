# frozen_string_literal: true

require 'coradoc/docx'
require 'coradoc/asciidoc'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

# Helper to build OOXML document fragments
module OoxmlHelper
  def build_document
    Uniword::Wordprocessingml::DocumentRoot.new
  end

  def build_heading(text, level:)
    para = Uniword::Wordprocessingml::Paragraph.new
    para.properties = Uniword::Wordprocessingml::ParagraphProperties.new
    para.properties.style = Uniword::Properties::StyleReference.new(
      value: "Heading#{level}"
    )
    run = Uniword::Wordprocessingml::Run.new
    run.text = Uniword::Wordprocessingml::Text.new(content: text)
    para.runs << run
    para
  end

  def build_paragraph(*runs_or_texts)
    para = Uniword::Wordprocessingml::Paragraph.new
    runs_or_texts.each do |rt|
      case rt
      when String
        run = Uniword::Wordprocessingml::Run.new
        run.text = Uniword::Wordprocessingml::Text.new(content: rt)
        para.runs << run
      when Uniword::Wordprocessingml::Run
        para.runs << rt
      end
    end
    para
  end

  def build_run(text, **formatting)
    run = Uniword::Wordprocessingml::Run.new
    run.text = Uniword::Wordprocessingml::Text.new(content: text)
    unless formatting.empty?
      run.properties = Uniword::Wordprocessingml::RunProperties.new
      run.properties.bold = Uniword::Properties::Bold.new if formatting[:bold]
      run.properties.italic = Uniword::Properties::Italic.new if formatting[:italic]
      run.properties.underline = Uniword::Properties::Underline.new if formatting[:underline]
      run.properties.strike = Uniword::Properties::Strike.new if formatting[:strike]
    end
    run
  end

  def build_table(rows_data)
    table = Uniword::Wordprocessingml::Table.new
    rows_data.each do |row_data|
      row = Uniword::Wordprocessingml::TableRow.new
      row_data.each do |cell_text|
        cell = Uniword::Wordprocessingml::TableCell.new
        cell.text = cell_text
        row.cells << cell
      end
      table.rows << row
    end
    table
  end

  def build_list_paragraph(text, num_id:, ilvl: 0)
    para = Uniword::Wordprocessingml::Paragraph.new
    para.properties = Uniword::Wordprocessingml::ParagraphProperties.new
    para.properties.num_id = num_id
    para.properties.ilvl = ilvl
    run = Uniword::Wordprocessingml::Run.new
    run.text = Uniword::Wordprocessingml::Text.new(content: text)
    para.runs << run
    para
  end

  def transform_to_core(doc)
    Coradoc::Docx.parse_to_core(doc)
  end

  def transform_to_adoc(doc)
    core = transform_to_core(doc)
    Coradoc.serialize(core, to: :asciidoc)
  end
end

RSpec.configure do |config|
  config.include OoxmlHelper
end

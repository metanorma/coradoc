# frozen_string_literal: true

require 'coradoc'

module Coradoc
  module Plugin
    # Coradoc plugin that spell-checks AsciiDoc documents via Kotoshu and
    # produces a Word-style YAML/JSON report.
    #
    # Architecture: the plugin never parses raw AsciiDoc itself. It asks Coradoc
    # for the format-neutral CoreModel tree, walks the tree to extract text
    # spans (with element path + source-line hint), runs each span through
    # Kotoshu, and collects misspellings into a Report.
    module Kotoshu
      autoload :VERSION, 'coradoc/plugin/kotoshu/version'
      autoload :TextExtractor, 'coradoc/plugin/kotoshu/text_extractor'
      autoload :ReportError, 'coradoc/plugin/kotoshu/report_error'
      autoload :Report, 'coradoc/plugin/kotoshu/report'
      autoload :Checker, 'coradoc/plugin/kotoshu/checker'
      autoload :Cli, 'coradoc/plugin/kotoshu/cli'
    end
  end
end

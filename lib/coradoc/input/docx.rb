require "word-to-markdown"
require "coradoc/input/html"
require "fileutils"

module Coradoc
  module Input
    module Docx
      def self.processor_id
        :docx
      end

      def self.processor_match?(filename)
        %w[.docx .doc].any? { |i| filename.downcase.end_with?(i) }
      end

      def self.processor_execute(input, options = {})
        image_dir = Dir.mktmpdir
        options = options.merge(sourcedir: image_dir)
        doc = WordToMarkdown.new(input, image_dir)
        doc = Coradoc::Input::Html.cleaner.preprocess_word_html(doc.document.html)
        options = WordToMarkdown::REVERSE_MARKDOWN_OPTIONS.merge(options)
        Coradoc::Input::Html.to_coradoc(doc, options)
      ensure
        FileUtils.rm_rf(image_dir)
      end

      def self.processor_postprocess(data, options)
        Coradoc::Input::Html.processor_postprocess(data, options)
      end

      # This processor prefers to work on original files.
      def self.processor_wants_filenames; true; end

      Coradoc::Input.define(self)
    end
  end
end

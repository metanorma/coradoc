require "coradoc/input/html"
require "fileutils"

module Coradoc
  module Input
    module Docx
      WORD_TO_MARKDOWN_MISSING_MSG =
        "DOCX input requires the 'word-to-markdown' gem, " \
        "which is unavailable on this platform. " \
        "See https://github.com/metanorma/coradoc/issues/192".freeze

      def self.windows_ruby4?
        Gem.win_platform? &&
          Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("4.0")
      end

      WORD_TO_MARKDOWN_AVAILABLE = if windows_ruby4?
                                     false
                                   else
                                     begin
                                       require "word-to-markdown"
                                       true
                                     rescue LoadError
                                       false
                                     end
                                   end

      def self.processor_id
        :docx
      end

      def self.processor_match?(filename)
        %w[.docx .doc].any? { |i| filename.downcase.end_with?(i) }
      end

      def self.assert_word_to_markdown!
        return if WORD_TO_MARKDOWN_AVAILABLE

        raise LoadError, WORD_TO_MARKDOWN_MISSING_MSG
      end

      def self.processor_execute(input, options = {})
        assert_word_to_markdown!
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

# frozen_string_literal: true

require 'coradoc'

module Coradoc
  module Output
    # Static HTML output processor
    #
    # Generates static HTML documents from CoreModel using the classic
    # rendering approach without JavaScript frameworks.
    #
    # @example Using the processor directly
    #   html = Coradoc::Output::HtmlStatic.processor_execute({ "doc.html" => document }, {})
    #
    # @example Using through Output module
    #   result = Coradoc::Output.process(document, format: :html_static)
    #
    class HtmlStatic
      extend Coradoc::Html::FormatDetection

      class << self
        def processor_id
          :html_static
        end

        def processor_match?(filename)
          html_extension?(filename)
        end

        # Process documents to static HTML
        # @param input [Hash<String, Object>] mapping of filenames to documents
        # @param options [Hash] processing options
        # @return [Hash<String, String>] mapping of filenames to HTML output
        def processor_execute(input, options = {})
          result = {}
          input.each do |filename, document|
            html = Coradoc::Html::Static.convert(document, options)
            result[filename] = html
          end
          result
        end
      end
    end

    # SPA (Single Page Application) HTML output processor
    #
    # Generates modern Vue.js + Tailwind CSS HTML documents from CoreModel.
    #
    # @example Using the processor directly
    #   html = Coradoc::Output::HtmlSpa.processor_execute({ "doc.html" => document }, {})
    #
    # @example Using through Output module
    #   result = Coradoc::Output.process(document, format: :html_spa)
    #
    class HtmlSpa
      extend Coradoc::Html::FormatDetection

      class << self
        def processor_id
          :html_spa
        end

        def processor_match?(filename)
          html_extension?(filename)
        end

        # Process documents to SPA HTML
        # @param input [Hash<String, Object>] mapping of filenames to documents
        # @param options [Hash] processing options
        # @return [Hash<String, String>] mapping of filenames to SPA HTML output
        def processor_execute(input, options = {})
          result = {}
          input.each do |filename, document|
            html = Coradoc::Html::Spa.convert(document, options)
            result[filename] = html
          end
          result
        end
      end
    end

    # Alias for HtmlSpa
    Spa = HtmlSpa
  end
end

# Register processors with the Output module
Coradoc::Output.define(Coradoc::Output::HtmlStatic)
Coradoc::Output.define(Coradoc::Output::HtmlSpa)

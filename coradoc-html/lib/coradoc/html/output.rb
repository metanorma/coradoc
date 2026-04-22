# frozen_string_literal: true

require 'coradoc/output'

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
      class << self
        # Processor identifier for registration
        # @return [Symbol] the processor ID
        def processor_id
          :html_static
        end

        # Check if this processor matches a given filename
        # @param filename [String] the filename to check
        # @return [Boolean] true if this processor handles the file type
        def processor_match?(filename)
          %w[.html .htm].any? { |ext| filename.downcase.end_with?(ext) }
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
      class << self
        # Processor identifier for registration
        # @return [Symbol] the processor ID
        def processor_id
          :html_spa
        end

        # Check if this processor matches a given filename
        # @param filename [String] the filename to check
        # @return [Boolean] true if this processor handles the file type
        def processor_match?(filename)
          %w[.html .htm].any? { |ext| filename.downcase.end_with?(ext) }
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

# frozen_string_literal: true

require_relative "converters/markup"
require_relative "converters/a"
require_relative "converters/aside"
require_relative "converters/audio"
require_relative "converters/blockquote"
require_relative "converters/br"
require_relative "converters/bypass"
require_relative "converters/code"
require_relative "converters/div"
require_relative "converters/dl"
require_relative "converters/drop"
require_relative "converters/em"
require_relative "converters/figure"
require_relative "converters/h"
require_relative "converters/head"
require_relative "converters/hr"
require_relative "converters/ignore"
require_relative "converters/img"
require_relative "converters/mark"
require_relative "converters/li"
require_relative "converters/ol"
require_relative "converters/p"
require_relative "converters/pass_through"
require_relative "converters/pre"
require_relative "converters/q"
require_relative "converters/strong"
require_relative "converters/sup"
require_relative "converters/sub"
require_relative "converters/table"
require_relative "converters/td"
require_relative "converters/th"
require_relative "converters/text"
require_relative "converters/tr"
require_relative "converters/video"
require_relative "converters/math"

module Coradoc
  module ReverseAdoc
    class HtmlConverter
      def self.to_coradoc(input, options = {})
        ReverseAdoc.config.with(options) do
          root = track_time "Loading input HTML document" do
            case input
            when String
              Nokogiri::HTML(input).root
            when Nokogiri::XML::Document
              input.root
            when Nokogiri::XML::Node
              input
            end
          end

          return "" unless root

          if pc = ReverseAdoc.config.processor
            if defined? pc::Preprocessor
              preprocessor = pc::Preprocessor

              root = track_time "Preprocessing document" do
                preprocessor.(root)
              end
            end
          end

          track_time "Converting input document tree to Coradoc tree" do
            Converters.lookup(root.name).to_coradoc(root)
          end
        end
      end

      def self.convert(input, options = {})
        ReverseAdoc.config.with(options) do
          coradoc = to_coradoc(input)
          result = track_time "Converting Coradoc tree into Asciidoc" do
            Coradoc::Generator.gen_adoc(coradoc)
          end
          track_time "Cleaning up the result" do
            ReverseAdoc.cleaner.tidy(result)
          end
        end
      end

      @track_time_indentation = 0
      def self.track_time(task)
        if ReverseAdoc.config.track_time
          warn "  " * @track_time_indentation +
            "* #{task} is starting..."
          @track_time_indentation += 1
          t0 = Time.now
          ret = yield
          time_elapsed = Time.now - t0
          @track_time_indentation -= 1
          warn "  " * @track_time_indentation +
            "* #{task} took #{time_elapsed.round(3)} seconds"
          ret
        else
          yield
        end
      end
    end
  end
end

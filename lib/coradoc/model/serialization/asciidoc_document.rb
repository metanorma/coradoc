# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocDocument
        attr_reader :sections

        def initialize(sections = [])
          @sections = sections
        end

        def self.parse(asciidoc_data, _options = {})
          parser = Coradoc::Parser::Base.new(asciidoc_data)
          new(parser.parse[:document])
        end

        def to_asciidoc(*)
          sections.map(&:to_asciidoc).join("\n\n")
        end

        def [](key)
          @sections[key]
        end

        def []=(key, value)
          @sections[key] = value
        end

        def to_h
          @sections
        end

        def map(&block)
          @sections.map(&block)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'registry'
require_relative 'serializers/document'
require_relative 'serializers/heading'
require_relative 'serializers/paragraph'
require_relative 'serializers/list'
require_relative 'serializers/code_block'
require_relative 'serializers/blockquote'
require_relative 'serializers/link'
require_relative 'serializers/image'
require_relative 'serializers/horizontal_rule'
require_relative 'serializers/table'
require_relative 'serializers/emphasis'
require_relative 'serializers/strong'
require_relative 'serializers/code'
require_relative 'serializers/strikethrough'
require_relative 'serializers/highlight'
require_relative 'serializers/subscript'
require_relative 'serializers/superscript'
require_relative 'serializers/underline'
require_relative 'serializers/cross_reference'
require_relative 'serializers/attribute_list'
require_relative 'serializers/math'
require_relative 'serializers/extension'
require_relative 'serializers/definition_list'
require_relative 'serializers/footnote'
require_relative 'serializers/footnote_reference'
require_relative 'serializers/abbreviation'
require_relative 'serializers/comment'
require_relative 'serializers/admonition'
require_relative 'serializers/example_block'
require_relative 'serializers/open_block'
require_relative 'serializers/sidebar'
require_relative 'serializers/verse'
require_relative 'serializers/pass'
require_relative 'serializers/literal'
require_relative 'serializers/hard_line_break'

module Coradoc
  module Markdown
    class Serializer
      # Auto-registers all built-in element serializers into a fresh
      # Registry. Called once per Runner (cached via `default_registry`).
      #
      # Adding a new element serializer = appending one entry here. No
      # lookup code changes — Open/Closed.
      module Registrations
        SERIALIZEABLE = [
          Serializers::Document,
          Serializers::Heading,
          Serializers::Paragraph,
          Serializers::List,
          Serializers::CodeBlock,
          Serializers::Blockquote,
          Serializers::Link,
          Serializers::Image,
          Serializers::HorizontalRule,
          Serializers::Table,
          Serializers::Emphasis,
          Serializers::Strong,
          Serializers::Code,
          Serializers::Strikethrough,
          Serializers::Highlight,
          Serializers::Subscript,
          Serializers::Superscript,
          Serializers::Underline,
          Serializers::CrossReference,
          Serializers::AttributeList,
          Serializers::Math,
          Serializers::Extension,
          Serializers::DefinitionList,
          Serializers::Footnote,
          Serializers::FootnoteReference,
          Serializers::Abbreviation,
          Serializers::Comment,
          Serializers::Admonition,
          Serializers::ExampleBlock,
          Serializers::OpenBlock,
          Serializers::Sidebar,
          Serializers::Verse,
          Serializers::Pass,
          Serializers::Literal,
          Serializers::HardLineBreak
        ].freeze

        @mutex = Mutex.new
        @default = nil

        class << self
          def default_registry
            @mutex.synchronize do
              @default ||= register_all(Registry.new)
            end
          end

          def fresh_registry
            register_all(Registry.new)
          end

          private

          def register_all(registry)
            SERIALIZEABLE.each { |klass| registry.register(klass.new) }
            registry
          end
        end
      end
    end
  end
end

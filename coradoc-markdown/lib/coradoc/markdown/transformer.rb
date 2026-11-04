# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module Markdown
    # Stage 1 -> 2 for Markdown: walks the block parser's raw tree and hands
    # every bound node to the BindingInflater (see Bindings). This class
    # holds no per-rule code; it keeps only what is genuinely stateful, the
    # Attribute List Definition table:
    #
    # * an ALD definition registers itself and yields no block;
    # * a standalone IAL resolves against the table (or is a fresh list).
    #
    class Transformer < Parsanol::Transform
      class << self
        # ALD storage - maps name to AttributeList
        attr_accessor :ald_registry

        # Active Coradoc::BindingInflater; the shipped bindings by default.
        def bindings
          @bindings || Bindings.inflater
        end

        # Run the block with another BindingInflater active.
        def with_bindings(inflater)
          previous = @bindings
          @bindings = inflater
          yield
        ensure
          @bindings = previous
        end

        # Transform AST into a Document model
        #
        # @param ast [Array] The parsed AST from BlockParser
        # @return [Coradoc::Markdown::Document] The document model
        def transform_document(ast)
          @ald_registry = {}
          blocks = Array(ast).map { |element| transform_element(element) }.compact
          Document.new(blocks: blocks)
        end

        # Transform a single element
        def transform_element(element)
          case element
          when nil then nil
          when Array then element.map { |e| transform_element(e) }.compact
          when Hash then transform_node(element)
          else Text.new(content: element.to_s)
          end
        end

        private

        def transform_node(node)
          return bindings.inflate(node) { |unbound| transform_residual(unbound) } if bindings.bound?(node)

          transform_residual(node)
        end

        # The nodes no binding claims.
        def transform_residual(node)
          if node.key?(:ald_name)
            register_ald(node)
            nil
          elsif node.key?(:ial) && !node.key?(:p) && !node.key?(:heading)
            resolve_ial(node[:ial])
          elsif node.key?(:ln)
            Paragraph.new(text: node[:ln].to_s)
          elsif node.key?(:text)
            Text.new(content: node[:text].to_s)
          end
        end

        def register_ald(node)
          name = node[:ald_name].to_s
          attrs = Bindings::Captures.parse_ial_content(node[:ial].to_s)
          @ald_registry[name] = AttributeList.new(name: name, **attrs)
        end

        # An IAL naming a registered ALD resolves to it; anything else is
        # a fresh attribute list.
        def resolve_ial(ial_content)
          content = ial_content.to_s.strip
          return @ald_registry[content] if content.match?(/\A\w+\z/) && @ald_registry.key?(content)

          attrs = Bindings::Captures.parse_ial_content(content)
          AttributeList.new(id: attrs[:id], classes: attrs[:classes], attributes: attrs[:attributes])
        end
      end
    end
  end
end

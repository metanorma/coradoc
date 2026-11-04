# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module Markdown
    # Stage 1 -> 2 for Markdown: walks the block parser's raw tree and hands
    # every node to the BindingInflater (see Bindings). It holds no rule
    # and no state of its own; the ALD table lives in a per-document
    # Bindings::Scope that the inflater passes to the scoped hooks.
    class Transformer < Parsanol::Transform
      class << self
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
          scope = Bindings::Scope.new
          Document.new(blocks: Array(ast).map { |element| transform_element(element, scope) }.compact)
        end

        # Transform a single element
        def transform_element(element, scope = Bindings::Scope.new)
          case element
          when nil then nil
          when Array then element.map { |e| transform_element(e, scope) }.compact
          when Hash then bindings.inflate(element, scope) { nil }
          else Text.new(content: element.to_s)
          end
        end
      end
    end
  end
end

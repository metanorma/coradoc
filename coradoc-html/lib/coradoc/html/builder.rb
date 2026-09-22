# frozen_string_literal: true

module Coradoc
  module Html
    # Builds HTML trees over the Leptris DOM using a
    # Nokogiri::HTML::Builder-style DSL. Single source of truth for
    # programmatic HTML construction in this gem (layout fallbacks,
    # asset tag emitters) — no raw HTML string concatenation anywhere.
    #
    #   Builder.new do |doc|
    #     doc.html(lang: 'en') do
    #       doc.head { doc.meta(charset: 'UTF-8') }
    #       doc.body { doc << body_html }
    #     end
    #   end.to_html
    #
    # Serialization uses leptris-ruby's HTML mode (#309): script/style
    # text is emitted unescaped and void elements are unclosed.
    class Builder
      # Methods that are builder API, not tag names.
      RESERVED = %i[text to_html to_s document parent].freeze

      attr_reader :document

      def initialize(document = Leptris::XML::Document.create, &block)
        @document = document
        @roots = []
        @parents = []
        instance_eval(&block) if block
      end

      # Tag DSL. A positional String argument becomes the element's text
      # content; the block receives the builder with the new element as
      # insertion parent; keyword arguments become attributes.
      def method_missing(name, *args, **attrs, &block)
        element = @document.create_element(name.to_s)
        attrs.each { |key, value| element[key.to_s] = value.to_s }

        args.each do |arg|
          next unless arg.is_a?(String)

          element.add_child(@document.create_text_node(arg))
        end

        if block
          @parents.push(element)
          begin
            yield self
          ensure
            @parents.pop
          end
        end

        if current
          current.add_child(element)
        else
          @roots << element
        end
        element
      end

      def respond_to_missing?(name, include_private = false)
        !RESERVED.include?(name) || super
      end

      # Raw markup insertion into the current element (parsed, never
      # concatenated as text).
      def <<(markup)
        current&.add_child(markup)
        self
      end

      # Text node insertion into the current element.
      def text(content)
        current&.add_child(@document.create_text_node(content.to_s))
        self
      end

      # Serializes with HTML semantics: script/style text unescaped,
      # void elements unclosed. Multiple top-level elements are joined
      # with newlines.
      def to_html
        @roots.map(&:to_html).join("\n")
      end
      alias to_s to_html

      private

      def current
        @parents.last
      end
    end
  end
end

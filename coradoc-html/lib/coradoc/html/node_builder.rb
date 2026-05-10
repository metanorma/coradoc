# frozen_string_literal: true

require 'nokogiri'

module Coradoc
  module Html
    # Nokogiri-based HTML element builder
    #
    # All HTML output in the HTML gem must use this module to construct
    # elements. Never concatenate raw HTML strings.
    module NodeBuilder
      class << self
        # Create a Nokogiri document fragment as the builder context
        def create_doc
          Nokogiri::HTML::DocumentFragment.parse('')
        end

        # Build a Nokogiri element node
        #
        # @param tag [String, Symbol] HTML tag name, or :fragment for a document fragment
        # @param content [String, Nokogiri::XML::Node, nil] Inner content
        # @param attrs [Hash] HTML attributes
        # @return [Nokogiri::XML::Element, Nokogiri::HTML::DocumentFragment]
        def build(tag, content = nil, **attrs)
          return build_fragment(content) if tag.to_s == 'fragment'

          doc = create_doc
          node = Nokogiri::XML::Node.new(tag.to_s, doc)

          attrs.each do |k, v|
            next if v.nil?

            val = v.to_s
            next if val.empty?

            node[k.to_s] = val
          end

          set_content(node, content)
          node
        end

        # Create a text node
        #
        # @param text [String] Text content
        # @return [Nokogiri::XML::Text]
        def text(text)
          doc = create_doc
          Nokogiri::XML::Text.new(text.to_s, doc)
        end

        # Append child nodes to a parent
        #
        # @param parent [Nokogiri::XML::Node] Parent node
        # @param children [Array<Nokogiri::XML::Node, String>] Children to add
        def append_children(parent, children)
          Array(children).each do |child|
            if child.is_a?(Nokogiri::XML::Node)
              parent.add_child(child)
            else
              parent.add_child(text(child.to_s))
            end
          end
        end

        private

        def build_fragment(content)
          doc = create_doc
          set_content(doc, content)
          doc
        end

        def set_content(node, content)
          case content
          when nil
            nil
          when Nokogiri::XML::Node
            node.add_child(content)
          when Array
            content.each { |c| set_content(node, c) }
          else
            frag = Nokogiri::HTML::DocumentFragment.parse(content.to_s)
            node.add_child(frag.children)
          end
        end
      end
    end
  end
end

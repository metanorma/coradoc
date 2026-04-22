# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Mixin for elements that can have anchors (IDs and references).
      #
      # The Anchorable module provides functionality for elements that can
      # be referenced from other parts of the document. It automatically
      # creates an Inline::Anchor based on the element's id attribute.
      #
      # @example Including Anchorable in a class
      #   class MyElement < Coradoc::AsciiDoc::Model::Base
      #     include Coradoc::AsciiDoc::Model::Anchorable
      #     attribute :id, :string
      #   end
      #
      # @example Using the generated anchor
      #   element = MyElement.new(id: "section1")
      #   element.anchor.to_adoc # => "[[section1]]"
      #
      module Anchorable
        # Hook called when module is included in a class
        #
        # Automatically adds the :anchor attribute to the including class.
        #
        # @param base [Class] The class including this module
        def self.included(base)
          base.class_eval do
            attribute :anchor, :string
          end
        end

        # Override initialize to set default anchor
        def initialize(*args)
          super
          @anchor ||= default_anchor
        end

        # Generate the default anchor based on the element's id
        #
        # @return [String, nil] The anchor string, or nil if no id
        def default_anchor
          id.nil? ? nil : "[[#{id}]]"
        end

        # Generate the anchor string for serialization
        #
        # @param inline [Boolean] If true, don't add trailing newline
        # @return [String] The serialized anchor string
        def gen_anchor(inline: false)
          return '' if anchor.nil?

          anchor_str = anchor.to_adoc
          if anchor_str.empty?
            ''
          else
            "#{anchor_str}#{inline ? '' : "\n"}"
          end
        end
      end
    end
  end
end

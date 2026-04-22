# frozen_string_literal: true

require 'uri'

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Link inline element for AsciiDoc documents.
        #
        # Links can be external URLs or internal references.
        #
        # @!attribute [r] path
        #   @return [String] The URL or path the link points to
        #
        # @!attribute [r] title
        #   @return [String, nil] Optional tooltip text for the link
        #
        # @!attribute [r] name
        #   @return [String, nil] Optional link text/alias
        #
        # @!attribute [r] right_constrain
        #   @return [Boolean] Whether to constrain the link on the right (default: false)
        #
        # @example Create an external link
        #   link = Coradoc::AsciiDoc::Model::Inline::Link.new
        #   link.path = "https://example.com"
        #   link.name = "Example Site"
        #   link.to_adoc # => "https://example.com[Example Site]"
        #
        # @example Create a link with title
        #   link = Coradoc::AsciiDoc::Model::Inline::Link.new
        #   link.path = "https://example.com"
        #   link.title = "Visit example"
        #   link.name = "Click here"
        #
        class Link < Base
          attribute :path, :string
          attribute :title, :string
          attribute :name, :string
          attribute :right_constrain, :boolean, default: -> { false }
        end
      end
    end
  end
end

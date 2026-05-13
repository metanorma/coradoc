# frozen_string_literal: true

module Coradoc
  module Markdown
    # Represents a kramdown extension
    #
    # Extension syntax: {::extension_name options /}
    # Common extensions:
    #   {::toc} - table of contents
    #   {::options key="value" /} - parser options
    #   {::comment}content{:/} - comment
    #   {::nomarkdown}content{:/} - raw HTML passthrough
    #
    class Extension < Base
      attribute :name, :string
      attribute :options, NamedValue, collection: true, default: []
      attribute :content, :string  # For block extensions with content
      attribute :body, :string     # Alias for content

      # Known extension types
      TYPES = {
        toc: :toc,
        options: :options,
        comment: :comment,
        nomarkdown: :nomarkdown,
        ignore: :ignore,
        if: :conditional,
        endif: :conditional
      }.freeze

      # Create a TOC extension
      # @param options [Hash] TOC options (levels, etc.)
      # @return [Extension]
      def self.toc(options = {})
        new(name: :toc, options: hash_to_named(options))
      end

      # Create an options extension
      # @param options [Hash] Parser options
      # @return [Extension]
      def self.options(options = {})
        new(name: :options, options: hash_to_named(options))
      end

      # Create a comment extension
      # @param content [String] Comment content
      # @return [Extension]
      def self.comment(content = '')
        new(name: :comment, content: content)
      end

      # Create a nomarkdown extension (passthrough)
      # @param content [String] Raw content to pass through
      # @return [Extension]
      def self.nomarkdown(content)
        new(name: :nomarkdown, content: content)
      end

      # Check if this is a specific extension type
      # @param type [Symbol] The extension type
      # @return [Boolean]
      def type?(type)
        name.to_sym == type
      end

      # Check if this is a self-closing extension
      # @return [Boolean]
      def self_closing?
        content.nil? || content.empty?
      end

      class << self
        private

        def hash_to_named(hash)
          return [] if hash.nil? || hash.empty?

          hash.map { |k, v| NamedValue.new(name: k.to_s, value: v.to_s) }
        end
      end
    end
  end
end

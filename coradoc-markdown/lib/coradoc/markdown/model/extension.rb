# frozen_string_literal: true

require_relative 'base'

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
      attribute :options, :hash, default: {}
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
        new(name: :toc, options: options)
      end

      # Create an options extension
      # @param options [Hash] Parser options
      # @return [Extension]
      def self.options(options = {})
        new(name: :options, options: options)
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

      # Convert to Markdown
      # @return [String]
      def to_md
        opts = options.empty? ? '' : " #{options_to_s}"
        if self_closing?
          "{::#{name}#{opts} /}"
        else
          "{::#{name}#{opts}}#{content}{:/}"
        end
      end

      private

      def options_to_s
        options.map do |k, v|
          %(#{k}="#{v}")
        end.join(' ')
      end
    end
  end
end

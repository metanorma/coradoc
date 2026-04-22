# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Represents a math block (block or inline)
    #
    # Block math syntax: $$...$$ on its own lines
    # Inline math syntax: $$...$$ within text
    #
    # Examples:
    #   $$\lambda_\alpha > 5$$
    #   $$1 + 1$$
    #
    class Math < Base
      attribute :content, :string
      attribute :inline, :boolean, default: false

      # Check if this is inline math
      # @return [Boolean]
      def inline?
        inline == true
      end

      # Create an inline math element
      # @param content [String] The math content
      # @return [Math]
      def self.inline(content)
        new(content: content, inline: true)
      end

      # Create a block math element
      # @param content [String] The math content
      # @return [Math]
      def self.block(content)
        new(content: content, inline: false)
      end

      # Convert to Markdown
      # @return [String]
      def to_md
        if inline?
          "$$#{content}$$"
        else
          "$$\n#{content}\n$$"
        end
      end
    end
  end
end

# frozen_string_literal: true

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

      prepend Behaviors::Math
    end
  end
end

# frozen_string_literal: true

module Coradoc
  module Markdown
    # HorizontalRule model representing a Markdown horizontal rule (---, ***, ___).
    #
    class HorizontalRule < Base
      attribute :style, :string, default: '---'
    end
  end
end

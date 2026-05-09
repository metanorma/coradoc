# frozen_string_literal: true

module Coradoc
  module Markdown
    class CrossReference < Base
      attribute :text, :string
      attribute :target, :string

      def to_md
        "[#{text}](##{target})"
      end
    end
  end
end

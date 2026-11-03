# frozen_string_literal: true

module Coradoc
  module Markdown
    # Heading model representing a Markdown heading (# to ######).
    #
    # @example Create a heading
    #   heading = Coradoc::Markdown::Heading.new(level: 1, text: "Title")
    #
    class Heading < Base
      attribute :level, :integer, default: 1
      attribute :text, :string

      prepend Behaviors::Heading
    end
  end
end

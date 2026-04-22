# frozen_string_literal: true

module Coradoc
  module Markdown
    # Table model representing a Markdown table.
    #
    class Table < Base
      attribute :headers, :string, collection: true
      attribute :rows, :string, collection: true, default: []
      attribute :alignments, :string, collection: true # :left, :center, :right
    end
  end
end

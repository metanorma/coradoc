# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for footnote references. The footnote body lives in
      # the catalog as a Content node; the Edge points at it.
      class FootnoteRefOptions < Edge::Options
        attribute :footnote_id, :string
      end
    end
  end
end

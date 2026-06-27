# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Em < Markup
        INSTANCE = new

        def coradoc_format_type
          'italic'
        end

        def markup_ancestor_tag_names
          %w[em i cite]
        end
      end

      register :em,   Em::INSTANCE
      register :i,    Em::INSTANCE
      register :cite, Em::INSTANCE
    end
  end
end

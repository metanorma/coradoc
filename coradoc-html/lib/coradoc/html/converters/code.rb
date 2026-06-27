# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Code < Markup
        INSTANCE = new

        def coradoc_format_type
          'monospace'
        end

        def markup_ancestor_tag_names
          %w[code tt kbd samp var]
        end
      end

      register :code, Code::INSTANCE
      register :tt,   Code::INSTANCE
      register :kbd,  Code::INSTANCE
      register :samp, Code::INSTANCE
      register :var,  Code::INSTANCE
    end
  end
end

# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Strong < Markup
          INSTANCE = new

          def coradoc_format_type
            'bold'
          end

          def markup_ancestor_tag_names
            %w[strong b]
          end
        end

        register :strong, Strong::INSTANCE
        register :b,      Strong::INSTANCE
      end
    end
  end
end

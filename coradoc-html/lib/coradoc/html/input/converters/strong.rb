# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Strong < Markup
          def coradoc_format_type
            'bold'
          end

          def markup_ancestor_tag_names
            %w[strong b]
          end
        end

        register :strong, Strong.new
        register :b,      Strong.new
      end
    end
  end
end

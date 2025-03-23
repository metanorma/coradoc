module Coradoc
  module Input
    module Html
      module Converters
        class Em < Markup
          def coradoc_class
            Coradoc::Element::Inline::Italic
          end

          def markup_ancestor_tag_names
            %w[em i cite]
          end
        end

        register :em, Em.new
        register :i,  Em.new
        register :cite, Em.new
      end
    end
  end
end

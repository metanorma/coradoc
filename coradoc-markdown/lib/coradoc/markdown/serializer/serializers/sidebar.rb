# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Sidebar < ElementSerializer
          handles_type ::Coradoc::Markdown::Sidebar

          def call(element, _ctx)
            title_html = element.title ? %(<div class="title">#{element.title}</div>\n) : ''
            %(<div class="sidebar">\n#{title_html}#{element.content.to_s}\n</div>)
          end
        end
      end
    end
  end
end

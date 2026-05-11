# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class CrossReference < Base
        class << self
          def to_html(model, _state = {})
            href = model.target.to_s
            text = if model.content&.to_s&.strip != ''
                     model.content.to_s
                   else
                     href
                   end

            link_href = href.start_with?('#') ? href : "##{href}"
            NodeBuilder.build(:a, escape_html(text), href: link_href).to_html
          end

          def to_coradoc(node, _state = {})
            href = node['href'].to_s
            text = node.text.strip

            if href.start_with?('#')
              ref_id = href[1..]
              content = text.empty? || text == ref_id ? nil : text
              Coradoc::CoreModel::CrossReferenceElement.new(
                target: ref_id,
                content: content
              )
            else
              Coradoc::CoreModel::LinkElement.new(
                target: href,
                content: text
              )
            end
          end
        end
      end
    end
  end
end

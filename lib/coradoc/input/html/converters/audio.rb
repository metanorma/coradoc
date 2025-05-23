module Coradoc
  module Input
    module Html
      module Converters
        class Audio < Base
          def to_coradoc(node, _state = {})
            src = node["src"]
            id = node["id"]
            title = extract_title(node)
            attributes = Coradoc::Element::AttributeList.new
            options = options(node)
            attributes.add_named("options", options) if options.any?
            Coradoc::Element::Audio.new(
              title:, id:, src:, attributes:,
            )
          end

          def options(node)
            autoplay = node["autoplay"]
            loop_attr = node["loop"]
            controls = node["controls"]
            [autoplay, loop_attr, controls].compact
          end
        end

        register :audio, Audio.new
      end
    end
  end
end

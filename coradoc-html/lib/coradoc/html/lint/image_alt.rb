# frozen_string_literal: true

module Coradoc
  module Html
    module Lint
      # HTML002 — images must carry alt text: images without alt
      # convert to AsciiDoc images with no accessible description.
      class ImageAlt < Coradoc::Lint::Rule
        rule_id 'HTML002'
        applies_to :html

        def check(document, path)
          Array(document).filter_map do |element|
            next unless element.is_a?(CoreModel::Image)
            next if element.alt && !element.alt.strip.empty?

            build_violation(path: path,
                            message: "image without alt text: #{element.src}")
          end
        end
      end
    end
  end
end

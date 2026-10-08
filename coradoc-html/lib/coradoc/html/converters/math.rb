# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Math < Base
        INSTANCE = new

        def to_coradoc(node, _state = {})
          # Leptris#to_s returns an inspect string; serialize the node
          stem = node.to_xml.tr("\n", ' ')
          if Html.input_config.mathml2asciimath
            require 'plurimath'
            stem = Plurimath::Math.parse(stem, :mathml).to_asciimath
          end

          unless stem.nil?
            stem = stem.gsub('[', '\\[')
            stem = stem.gsub(']', '\\]')
            loop do
              new_stem = stem.gsub(/\(\(([^)]{1,100})\)\)/, '(\\1)')
              break if new_stem == stem

              stem = new_stem
            end
          end

          Coradoc::CoreModel::StemElement.new(
            content: stem,
            stem_type: 'mathml'
          )
        end
      end

      register :math, Math::INSTANCE
    end
  end
end

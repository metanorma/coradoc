# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Sup < Base
        INSTANCE = new
        include PositionalFormatting

        private

        def element_class
          Coradoc::CoreModel::SuperscriptElement
        end
      end

      register :sup, Sup::INSTANCE
    end
  end
end

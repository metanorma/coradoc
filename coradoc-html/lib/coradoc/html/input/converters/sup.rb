# frozen_string_literal: true

require_relative 'positional_formatting'

module Coradoc
  module Input
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
end

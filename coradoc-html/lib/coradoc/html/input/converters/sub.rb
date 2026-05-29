# frozen_string_literal: true

require_relative 'positional_formatting'

module Coradoc
  module Input
    module Html
      module Converters
        class Sub < Base
          include PositionalFormatting

          private

          def element_class
            Coradoc::CoreModel::SubscriptElement
          end
        end

        register :sub, Sub.new
      end
    end
  end
end

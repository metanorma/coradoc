# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Sub < Base
          INSTANCE = new
          include PositionalFormatting

          private

          def element_class
            Coradoc::CoreModel::SubscriptElement
          end
        end

        register :sub, Sub::INSTANCE
      end
    end
  end
end

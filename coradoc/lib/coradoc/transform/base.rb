# frozen_string_literal: true

module Coradoc
  module Transform
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def transform(model)
          raise NotImplementedError, "#{name} must implement .transform"
        end
      end

      def transform(model)
        self.class.transform(model)
      end
    end
  end
end

# frozen_string_literal: true

module Coradoc
  module Model
    module Anchorable
      def self.included(base)
        base.class_eval do
          attribute :anchor, method: :default_anchor
        end
      end

      def default_anchor
        @anchor.nil? ? id.nil? ? nil : Inline::Anchor.new(id) : @anchor
      end
    end
  end
end

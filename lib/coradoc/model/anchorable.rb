# frozen_string_literal: true

module Coradoc
  module Model
    module Anchorable
      def default_anchor
        @anchor.nil? ? id.nil? ? nil : Inline::Anchor.new(id) : @anchor
      end
    end
  end
end

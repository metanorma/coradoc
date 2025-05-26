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
        id.nil? ? nil : Inline::Anchor.new(id: id)
      end

      def gen_anchor(inline: false)
        return "" if anchor.nil? || id.nil? || id.empty?

        anchor_str = anchor.to_asciidoc
        if anchor_str.empty?
          ""
        else
          "#{anchor_str}#{inline ? '' : "\n"}"
        end
      end
    end
  end
end

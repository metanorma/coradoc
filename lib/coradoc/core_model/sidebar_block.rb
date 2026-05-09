# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Sidebar block — a delimited block for sidebars
    class SidebarBlock < Block
      def self.semantic_type = :sidebar

      attribute :block_semantic_type, :string, default: -> { 'sidebar' }
    end
  end
end

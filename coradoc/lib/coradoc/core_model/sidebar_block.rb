# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Sidebar block — a delimited block for sidebars
    class SidebarBlock < Block
      def self.semantic_type = :sidebar
    end
  end
end

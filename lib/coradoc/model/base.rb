# frozen_string_literal: true

# require "lutaml/model"

module Coradoc
  module Model
    class Base < Lutaml::Model::Serializable
      attribute :id, :string

      # Generate a warning message whenever this method is called.
      def simplify_block_content(content)
        warn "[DEPRECATION] #simplify_block_content is called inside a Lutaml Model.  This is still a WIP."
        # print part of the stack trace
        caller_locations(1, 3).each do |location|
          warn "  #{location.path}:#{location.lineno} in #{location.label}"
        end

        content
      end
    end
  end
end

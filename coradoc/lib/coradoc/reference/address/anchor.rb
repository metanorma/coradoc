# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # In-document anchor — the most common navigation target.
      # Matches raw strings starting with "#" plus bareword names that
      # don't look like document IDs or external URLs.
      #
      #   "#intro"     => anchor target "intro"
      #   "intro"      => anchor target "intro"
      #   "footnote-1" => anchor target "footnote-1"
      module Anchor
        module_function

        def scheme_name
          :anchor
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          stripped = raw.to_s
          return false if stripped == '#'
          return true if stripped.start_with?('#')

          stripped.match?(/\A[\w.\-]+\z/)
        end

        def parse(raw)
          target = raw.to_s.delete_prefix('#')
          new_address(target: target)
        end

        def serialize(address)
          target = address.target
          return '' if target.nil? || target.empty?

          "##{target}"
        end

        def new_address(target:)
          Address.new(scheme: 'anchor', target: target)
        end
      end
    end
  end
end

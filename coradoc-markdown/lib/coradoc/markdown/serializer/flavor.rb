# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      # Named Markdown flavor profiles.
      #
      # Each flavor bundles sensible defaults for the 5 spec options.
      # Callers can override any option via `Serializer.build`.
      #
      # Adding a new flavor = adding one entry here. No serializer code
      # needs to change — Open/Closed.
      module Flavor
        PROFILES = {
          commonmark: {
            markdown_flavor: :commonmark,
            admonition_style: :html,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          },
          gfm: {
            markdown_flavor: :gfm,
            admonition_style: :github,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          },
          kramdown: {
            markdown_flavor: :kramdown,
            admonition_style: :html,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          },
          pandoc: {
            markdown_flavor: :pandoc,
            admonition_style: :html,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          },
          vitepress: {
            markdown_flavor: :vitepress,
            admonition_style: :container,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          },
          php_markdown_extra: {
            markdown_flavor: :php_markdown_extra,
            admonition_style: :html,
            definition_list_nested: :html,
            suppress_comments: true,
            autolinks: true
          }
        }.freeze

        DEFAULT_FLAVOR = :gfm

        class << self
          def names
            PROFILES.keys
          end

          def known?(name)
            PROFILES.key?(name.to_sym)
          end

          def resolve(name)
            profile = PROFILES[name.to_sym] || PROFILES[DEFAULT_FLAVOR]
            profile.dup
          end

          def default
            PROFILES[DEFAULT_FLAVOR]
          end
        end
      end
    end
  end
end

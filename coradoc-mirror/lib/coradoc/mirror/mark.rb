# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Mirror
    # ProseMirror-compatible inline mark (formatting annotation).
    #
    # Marks decorate inline text nodes with formatting semantics like
    # bold, italic, link, etc. Wire format:
    #
    #   { "type": "strong" }
    #   { "type": "link", "attrs": { "href": "..." } }
    #
    # All built-in Mark subclasses live below in this file so the
    # TYPE_TO_CLASS registry at the bottom can see every PM_TYPE at
    # load time. Adding a new mark type = adding one subclass + letting
    # the registry walker pick it up (OCP).
    class Mark < Lutaml::Model::Serializable
      PM_TYPE = 'mark'

      attribute :type, :string, default: -> { self.class::PM_TYPE }

      key_value do
        map 'type', to: :type, render_default: true
      end

      def text_content
        ''
      end
    end
  end
end

module Coradoc
  module Mirror
    class Mark
      # ── Marks without attrs ──

      class Bold < Mark
        PM_TYPE = 'strong'
      end

      class Italic < Mark
        PM_TYPE = 'emphasis'
      end

      class Monospace < Mark
        PM_TYPE = 'code'
      end

      class Underline < Mark
        PM_TYPE = 'underline'
      end

      class Strikethrough < Mark
        PM_TYPE = 'strike'
      end

      class Subscript < Mark
        PM_TYPE = 'subscript'
      end

      class Superscript < Mark
        PM_TYPE = 'superscript'
      end

      class Highlight < Mark
        PM_TYPE = 'highlight'
      end

      # ── Marks with attrs ──

      class Link < Mark
        PM_TYPE = 'link'

        class Attrs < Lutaml::Model::Serializable
          attribute :href, :string

          key_value do
            map 'href', to: :href
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end

      class CrossReference < Mark
        PM_TYPE = 'xref'

        class Attrs < Lutaml::Model::Serializable
          attribute :target, :string
          attribute :resolved, :string

          key_value do
            map 'target', to: :target
            map 'resolved', to: :resolved
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end

      class Stem < Mark
        PM_TYPE = 'stem'

        class Attrs < Lutaml::Model::Serializable
          attribute :stem_type, :string

          key_value do
            map 'stem_type', to: :stem_type
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end

      class Span < Mark
        PM_TYPE = 'span'

        class Attrs < Lutaml::Model::Serializable
          attribute :role, :string

          key_value do
            map 'role', to: :role
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end
    end
  end
end

module Coradoc
  module Mirror
    class Mark
      # Polymorphic class map — flat hash from PM_TYPE wire string to
      # fully-qualified Ruby class name. Used by Node and Mark mappings
      # to dispatch polymorphic deserialization. Populated once after
      # all subclasses are defined above.
      TYPE_TO_CLASS = begin
        result = {}
        Mark.constants.each do |name|
          k = Mark.const_get(name)
          next unless k.is_a?(Class) && k < Mark && k::PM_TYPE != 'mark'

          result[k::PM_TYPE] = k.name
        end
        result.freeze
      end

      # Frozen polymorphic option block. Referenced verbatim by every
      # Node mapping that has a `marks` collection.
      POLYMORPHIC = {
        attribute: 'type',
        class_map: TYPE_TO_CLASS
      }.freeze
    end
  end
end

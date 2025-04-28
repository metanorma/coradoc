# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Citation < Base
        attribute :cross_reference, Coradoc::Model::Inline::CrossReference
        attribute :comment, :string

        asciidoc do
          map_attribute "cross_reference", to: :cross_reference
          map_attribute "comment", to: :comment
        end

        def to_asciidoc
          adoc = "[.source]\n".dup
          adoc << cross_reference.to_asciidoc if cross_reference
          adoc << "\n" if cross_reference && !comment
          adoc << Coradoc::Generator.gen_adoc(comment) if comment
          adoc
        end
      end
    end
  end
end

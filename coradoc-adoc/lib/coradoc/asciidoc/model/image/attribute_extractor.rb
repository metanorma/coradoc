# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Image
        # Pure-function promoter: lifts semantically meaningful slots out of
        # a generic {Model::AttributeList} into the typed fields declared on
        # an image class, and the inverse — composes a serialisable
        # AttributeList from typed fields + residual.
        #
        # The promotion map is owned by the target class itself, via
        # +promoted_positional+ and +promoted_named+. This module is the
        # single place that consumes those declarations, so adding a new
        # promoted field is a one-line class-level change (OCP).
        #
        # Positional slots are consumed by index; named slots are removed
        # from the residual list so they don't appear twice. The residual
        # list preserves order and identity for everything that wasn't
        # promoted (e.g. +scaledwidth+, +pdfwidth+, +opts+).
        #
        # @example Extract for an inline image
        #   list = Model::AttributeList.new
        #   list.add_positional('Alt', 'Thumb')
        #   list.add_named('width', '640')
        #   extracted, residual = AttributeExtractor.call(list, InlineImage)
        #   extracted  # => { alt: 'Alt', role: 'Thumb', width: '640' }
        #   residual.positional   # => []
        #   residual.named         # => []
        #
        # @example Compose for serialisation
        #   AttributeExtractor.compose(image)
        #   # => Model::AttributeList with positional [alt, role] + named
        #   #    [width, height, link] + residual attrs, in declaration order
        #
        module AttributeExtractor
          module_function

          # @param attribute_list [Model::AttributeList, nil]
          # @param target_class [Class] an Image::Core subclass
          # @return [Array<(Hash{Symbol=>String}, Model::AttributeList)>]
          #   a tuple of promoted typed values and the residual list
          def call(attribute_list, target_class)
            source = attribute_list || Model::AttributeList.new
            residual = Model::AttributeList.new
            extracted = {}

            promote_positional(extracted, residual, source, target_class)
            promote_named(extracted, residual, source, target_class)

            [extracted, residual]
          end

          # Inverse of {call}: rebuild a serialisable AttributeList from a
          # model's typed fields plus its residual list. Used by the AsciiDoc
          # image serializer so round-trips reproduce the original syntax.
          #
          # A field that's declared in both +promoted_positional+ and
          # +promoted_named+ (e.g. inline image +role+) is emitted only
          # once — via its positional slot when filled, otherwise via named.
          # @param model [Coradoc::AsciiDoc::Model::Image::Core]
          # @return [Model::AttributeList]
          def compose(model)
            composed = Model::AttributeList.new
            filled = compose_positional(composed, model)
            compose_named(composed, model, filled)
            append_residual(composed, model.attributes)
            composed
          end

          def compose_positional(composed, model)
            filled = []
            model.class.promoted_positional.each do |attr_name|
              value = model.public_send(attr_name)
              next if value.nil? || value.to_s.empty?

              composed.add_positional(value.to_s)
              filled << attr_name
            end
            filled
          end

          def compose_named(composed, model, filled)
            model.class.promoted_named.each do |attr_name|
              next if filled.include?(attr_name)

              value = model.public_send(attr_name)
              next if value.nil? || value.to_s.empty?

              composed.add_named(attr_name.to_s, value.to_s)
            end
          end

          def promote_positional(extracted, residual, source, target_class)
            promoted = target_class.promoted_positional
            source.positional.each_with_index do |positional_attr, index|
              attr_name = promoted[index]
              value = positional_attr.value
              if attr_name && !value.to_s.empty?
                extracted[attr_name] = value.to_s
              else
                residual.add_positional(value)
              end
            end
          end

          def promote_named(extracted, residual, source, target_class)
            promoted_names = target_class.promoted_named.to_set(&:to_s)
            source.named.each do |named_attr|
              promote_one_named(extracted, residual, named_attr, promoted_names)
            end
          end

          def promote_one_named(extracted, residual, named_attr, promoted_names)
            name_str = named_attr.name.to_s
            unless promoted_names.include?(name_str)
              residual.add_named(named_attr.name, named_attr.value)
              return
            end
            # Positional promotion wins: a slot already filled positionally
            # is not overwritten by a same-named entry (rare, but possible
            # when both `[alt, role, role=X]` are supplied).
            key = name_str.to_sym
            return if extracted.key?(key)

            value = named_attr.value.first&.to_s
            return if value.nil? || value.empty?

            extracted[key] = value
          end

          def append_residual(composed, residual)
            return unless residual.is_a?(Model::AttributeList)

            residual.positional.each { |p| composed.add_positional(p.value) }
            residual.named.each { |n| composed.add_named(n.name, n.value) }
          end
        end
      end
    end
  end
end

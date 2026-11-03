# frozen_string_literal: true

module Coradoc
  module Roundtrip
    # Reduces a CoreModel tree to plain Ruby data so two trees can be
    # compared structurally and the first difference located by path.
    #
    # Positional bookkeeping (`source_line`) is not part of document
    # meaning and is dropped; everything else participates.
    module Projection
      IGNORED_ATTRIBUTES = %i[source_line].freeze

      module_function

      # @param node [Object] a CoreModel node, collection or scalar
      # @return [Object] hashes, arrays and scalars only
      def of(node)
        case node
        when Lutaml::Model::Serializable then model(node)
        when Array then node.map { |child| of(child) }
        else node
        end
      end

      # @return [Array(String, Object, Object), nil] path and the two values
      #   at the first difference, or nil when equal
      def first_difference(left, right, path = '$')
        return nil if left == right

        if left.is_a?(Hash) && right.is_a?(Hash)
          hash_difference(left, right, path)
        elsif left.is_a?(Array) && right.is_a?(Array)
          array_difference(left, right, path)
        else
          [path, left, right]
        end
      end

      def model(node)
        attrs = node.class.attributes.keys - IGNORED_ATTRIBUTES
        attrs.each_with_object({ '@type' => node.class.name.split('::').last }) do |name, hash|
          value = of(node.public_send(name))
          hash[name.to_s] = value unless value.nil? || value == []
        end
      end

      def hash_difference(left, right, path)
        (left.keys | right.keys).each do |key|
          found = first_difference(left[key], right[key], "#{path}.#{key}")
          return found if found
        end
        nil
      end

      def array_difference(left, right, path)
        [left.size, right.size].max.times do |i|
          found = first_difference(left[i], right[i], "#{path}[#{i}]")
          return found if found
        end
        nil
      end
    end
  end
end

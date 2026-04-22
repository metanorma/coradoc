# frozen_string_literal: true

module Coradoc
  # Document normalization for reliable comparison and round-trip testing.
  #
  # Provides utilities to canonicalize documents to a normalized form,
  # enabling reliable comparison and round-trip testing.
  #
  # Uses lutaml-model's to_hash for serialized attributes, supplemented
  # with raw Ruby attributes (children, nested) that to_hash doesn't capture.
  #
  # @example Comparing documents
  #   doc1 = Coradoc.parse(text1, format: :asciidoc)
  #   doc2 = Coradoc.parse(text2, format: :asciidoc)
  #
  #   if Coradoc::Normalize.documents_equal?(doc1, doc2)
  #     puts "Documents are equivalent"
  #   end
  #
  module Normalize
    class << self
      # Check if two documents are semantically equal
      #
      # @param doc1 [CoreModel::Base] First document
      # @param doc2 [CoreModel::Base] Second document
      # @param options [Hash] Comparison options
      # @return [Boolean] True if documents are equal
      def documents_equal?(doc1, doc2, **options)
        normalize(doc1, **options) == normalize(doc2, **options)
      end

      # Normalize a document to canonical form
      #
      # @param doc [CoreModel::Base] Document to normalize
      # @param options [Hash] Normalization options
      # @option options [Boolean] :normalize_whitespace Normalize whitespace in strings
      # @return [Hash, String] Normalized representation
      def normalize(doc, **options)
        return nil if doc.nil?

        normalize_value(doc, **options)
      end

      # Compute a hash fingerprint for a document
      #
      # @param doc [CoreModel::Base] Document to fingerprint
      # @return [String] SHA256 fingerprint
      def fingerprint(doc)
        require 'digest'
        normalized = normalize(doc)
        Digest::SHA256.hexdigest(normalized.to_json)
      rescue StandardError
        Digest::SHA256.hexdigest(normalize(doc).to_s)
      end

      private

      def normalize_value(value, **options)
        case value
        when Array
          value.map { |v| normalize_value(v, **options) }
        when Hash
          value.transform_values { |v| normalize_value(v, **options) }
          # Ensure type info is present

        when String
          normalize_string(value, **options)
        when CoreModel::Base
          normalize_model(value, **options)
        when Lutaml::Model::Serializable
          normalize_serializable(value, **options)
        else
          value
        end
      end

      # Normalize CoreModel objects using to_hash
      def normalize_model(obj, **options)
        normalize_via_to_hash(obj, **options)
      end

      # Use to_hash for lutaml-model declared attributes
      def normalize_via_to_hash(obj, **options)
        hash = obj.to_hash
        result = hash.transform_values { |v| normalize_value(v, **options) }
        result['_type'] = obj.class.name.split('::').last
        result
      rescue SystemStackError, Lutaml::Model::IncorrectModelError
        # Fallback for:
        # - deeply recursive structures that exhaust the stack
        # - type validation errors (e.g., children collection has mixed String/Base)
        normalize_via_ivar(obj, **options)
      end

      # Normalize generic Serializable objects using to_hash
      def normalize_serializable(obj, **options)
        normalize_via_to_hash(obj, **options)
      end

      # Fallback: normalize by extracting public attributes
      def normalize_via_ivar(obj, **_options)
        result = {}

        obj.instance_variables.each do |var|
          key = var.to_s.delete_prefix('@')
          next if key.start_with?('using_default', 'lutaml_')

          value = obj.public_send(key)
          next if value.nil?
          next if value.respond_to?(:empty?) && value.empty?

          result[key] = normalize_value(value)
        end

        result['_type'] = obj.class.name.split('::').last
        result
      end

      def normalize_string(str, **options)
        return nil if str.nil?

        s = str.to_s

        s = s.gsub(/\s+/, ' ').strip if options[:normalize_whitespace]

        s.gsub(/\r\n/, "\n").tr("\r", "\n")
      end
    end

    # Difference reporter for comparing documents
    class DiffReporter
      attr_reader :differences

      def initialize
        @differences = []
      end

      def compare(doc1, doc2, path = '')
        @differences = []
        compare_values(doc1, doc2, path)
        @differences
      end

      def equal?
        @differences.empty?
      end

      private

      def compare_values(val1, val2, path)
        if val1.class != val2.class
          @differences << {
            path: path,
            type: :type_mismatch,
            expected: val1.class.name,
            actual: val2.class.name
          }
        elsif val1.is_a?(Hash)
          compare_hashes(val1, val2, path)
        elsif val1.is_a?(Array)
          compare_arrays(val1, val2, path)
        elsif val1 != val2
          @differences << {
            path: path,
            type: :value_mismatch,
            expected: val1,
            actual: val2
          }
        end
      end

      def compare_hashes(hash1, hash2, path)
        all_keys = (hash1.keys + hash2.keys).uniq

        all_keys.each do |key|
          key_path = path.empty? ? key.to_s : "#{path}.#{key}"

          if !hash1.key?(key)
            @differences << {
              path: key_path,
              type: :missing_key,
              expected: nil,
              actual: hash2[key]
            }
          elsif !hash2.key?(key)
            @differences << {
              path: key_path,
              type: :extra_key,
              expected: hash1[key],
              actual: nil
            }
          else
            compare_values(hash1[key], hash2[key], key_path)
          end
        end
      end

      def compare_arrays(arr1, arr2, path)
        if arr1.length != arr2.length
          @differences << {
            path: path,
            type: :length_mismatch,
            expected: arr1.length,
            actual: arr2.length
          }
        end

        max_length = [arr1.length, arr2.length].max
        max_length.times do |i|
          index_path = "#{path}[#{i}]"
          compare_values(arr1[i], arr2[i], index_path)
        end
      end
    end
  end
end

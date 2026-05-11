# frozen_string_literal: true

module Coradoc
  module CoreModel
    # A single metadata entry (key-value pair)
    class MetadataEntry < Base
      attribute :key, :string
      attribute :value, :string
    end

    # Represents metadata associated with a document element
    #
    # Stores arbitrary key-value pairs for tracking source location,
    # processing information, and other contextual data.
    #
    # @example
    #   meta = Metadata.new
    #   meta["source_line"] = 42
    #   meta["parser_version"] = "1.0.0"
    class Metadata < Base
      attribute :entries, MetadataEntry, collection: true

      # Get a metadata value by key
      # @param key [String] The metadata key
      # @return [String, nil] The value or nil if not found
      def [](key)
        return nil if entries.nil?

        find_entry(key)&.value
      end

      # Set a metadata value
      # @param key [String] The metadata key
      # @param value [String] The value to set
      def []=(key, value)
        self.entries ||= []
        existing = find_entry(key)
        if existing
          existing.value = value
        else
          entries << MetadataEntry.new(key: key, value: value)
        end
      end

      # Check if a key exists
      # @param key [String] The key to check
      # @return [Boolean] True if key exists
      def key?(key)
        return false if entries.nil?

        !find_entry(key).nil?
      end

      # Get all keys
      # @return [Array<String>] List of keys
      def keys
        return [] if entries.nil?

        entries.map(&:key)
      end

      # Convert to hash representation
      # @return [Hash] Hash of all metadata entries
      def to_h
        return {} if entries.nil?

        entries.each_with_object({}) { |entry, hash| hash[entry.key] = entry.value }
      end

      private

      def find_entry(key)
        return nil if entries.nil?

        entries.find { |e| e.key == key }
      end
    end
  end
end

# frozen_string_literal: true

require 'json'
require 'fileutils'

module Coradoc
  module SourceGraph
    # Persistence for the twin in the XDG cache dir. A single JSON
    # map: realpath → { id, digest, edges }. Node ids are minted
    # lazily and live ONLY here — never inside source files. The
    # store is a cache in the strict sense: regenerable, LRU-capped,
    # and safe to delete at any time.
    #
    # Location precedence:
    #   CORADOC_CACHE_DIR  explicit override (CI, containers)
    #   XDG_CACHE_HOME     XDG base directory
    #   ~/.cache           default
    class Sidecar
      MAX_ENTRIES = 4096
      FILENAME = 'source_graph.json'

      attr_reader :dir

      def self.default
        new(default_dir)
      end

      def self.default_dir
        ENV['CORADOC_CACHE_DIR'] ||
          File.join(ENV['XDG_CACHE_HOME'] || File.join(Dir.home, '.cache'),
                    'coradoc')
      end

      def initialize(dir)
        @dir = File.expand_path(dir)
        @entries = nil
        @next_id = nil
      end

      def path
        File.join(@dir, FILENAME)
      end

      # All persisted records: path => { id:, digest:, edges: }.
      def entries
        @entries ||= read_entries
      end

      def record_for(path)
        entries[File.expand_path(path)]
      end

      # Persist +records+ (hashes with path/digest/edges). Mints ids
      # for records that lack one, keeps the most recently written
      # MAX_ENTRIES records. Returns the records with ids assigned.
      def write(records)
        records = records.map(&:dup)
        records.each { |rec| rec[:id] ||= mint_id }
        merged = entries.merge(build_records(records))
        @entries = evict(merged)
        @next_id = nil
        FileUtils.mkdir_p(@dir)
        File.write(path, JSON.pretty_generate(@entries))
        records
      end

      private

      def read_entries
        return {} unless File.exist?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError, Errno::ENOENT
        {}
      end

      def build_records(records)
        records.each_with_object({}) do |rec, out|
          out[rec[:path]] = { 'id' => rec[:id] || mint_id,
                              'digest' => rec[:digest],
                              'edges' => rec[:edges] }
        end
      end

      # Insertion order is recency: dropping the oldest MAX_ENTRIES
      # records is an LRU approximation for a JSON map.
      def evict(merged)
        merged.to_a.last(MAX_ENTRIES).to_h
      end

      def mint_id
        @next_id = ((@next_id || entries.values.map { |r| r['id'].to_i }.max || 0) + 1)
        format('n%08d', @next_id)
      end
    end
  end
end

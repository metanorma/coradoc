# frozen_string_literal: true

require 'digest'

module Coradoc
  module SourceGraph
    # One file in the twin. Levels materialize on demand and demote
    # automatically when the underlying file drifts:
    #
    #   Level 0 (stat)    File::Stat — size and mtime, free
    #   Level 1 (digest)  SHA256 of the bytes, read only when stat is
    #                     inconclusive (same size + mtime)
    #   Level 2 (parsed)  format tree from the registered format module
    #
    # CoreModel is not a level: it is a cached materialization
    # (+core+) derived from the parsed level via the format module's
    # +to_core+. Both caches drop together with the parsed level.
    class FileNode
      attr_accessor :graph_digest
      attr_reader :path
      # Identity minted by the sidecar; assigned after persistence.
      attr_accessor :id

      # @param path [String] absolute, real path of the file
      # @param id [String] sidecar-minted identity
      # @param format [Symbol, nil] registered format name; nil means
      #   detect from the extension
      def initialize(path, id: nil, format: nil)
        @path = File.expand_path(path)
        @id = id
        @format = format
        clear_parsed
      end

      def format
        @format ||= FormatCatalog.detect_format(@path)
      end

      # Level 0. Raises if the file is gone — a missing file is a
      # hard fact, not a stale one.
      def stat
        File.stat(@path)
      end

      # Level 1. Bytes are read only when the cached digest can't be
      # trusted from stat alone (size/mtime drifted).
      def digest
        if @digest && fresh_stat?
          @digest
        else
          @stat_snapshot = stat_snapshot
          @digest = compute_digest
        end
      end

      # Level 2. The format-specific model tree, parsed on first call.
      # Re-parses after any demotion.
      def parsed
        return @parsed if @parsed

        format_module.parse(File.read(@path)).tap do |tree|
          @parsed = tree
          @derived_digest = digest
        end
      end

      # Cached CoreModel materialized from the parsed level. Drops
      # together with the parsed level on demotion.
      def core
        @core ||= format_module.to_core(parsed)
      end

      def parsed?
        !@parsed.nil?
      end

      # True when the file's bytes still match the digest the derived
      # state was built from. Byte-accurate: reads the file. A node
      # with no derived state (never parsed, never warmed) is
      # vacuously fresh.
      def fresh?
        @derived_digest.nil? || @derived_digest == compute_digest
      end

      # Demote to Level 0/1: drop the parsed tree and the derived
      # CoreModel. Called by the graph when this file or one of its
      # includes drifted.
      def demote
        clear_parsed
      end

      # Digest over the include-graph shape: which files this node
      # pulls in, paired with their content digests. Computed by the
      # graph, which owns the edges.

      # Digest the current derived state was built from.
      attr_reader :derived_digest

      # Seed the derived anchor from the sidecar without reading
      # bytes; the stat snapshot taken alongside guards Level-1 reuse.
      def digest_warm(digest)
        return if digest.nil?

        @derived_digest = digest
        @digest = digest
        @stat_snapshot = stat_snapshot
      end

      # Stat fingerprint used to decide whether the cached digest can
      # be trusted without reading bytes.
      def stat_snapshot
        s = stat
        [s.size, s.mtime.to_i]
      end

      private

      def format_module
        mod = FormatCatalog.get_format(format) unless format.nil?
        if mod.nil?
          raise(Coradoc::UnsupportedFormatError.new(format || File.extname(@path),
                                                    available: FormatCatalog.registered_formats))
        end

        mod
      end

      def fresh_stat?
        @stat_snapshot.nil? || @stat_snapshot == stat_snapshot
      end

      def digest_matches?
        @digest.nil? || @digest == compute_digest
      end

      def compute_digest
        Digest::SHA256.file(@path).hexdigest
      end

      def clear_parsed
        @parsed = nil
        @core = nil
        @derived_digest = nil
      end
    end
  end
end

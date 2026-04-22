# frozen_string_literal: true

require 'digest'

module Coradoc
  module AsciiDoc
    module Parser
      # Parser cache for optimizing repeated parses of the same content
      #
      # This is an opt-in feature that caches parse results based on content hashing.
      # Useful for IDE integrations, watch mode, or any scenario where the same
      # content is parsed multiple times.
      #
      # @example Basic usage
      #   cache = Coradoc::AsciiDoc::Parser::Cache.new
      #   ast = cache.fetch_or_parse(content) { Parser::Base.parse(content) }
      #
      # @example With size limit
      #   cache = Coradoc::AsciiDoc::Parser::Cache.new(max_size: 100)
      #
      # @example Global cache (use with caution)
      #   Coradoc::AsciiDoc::Parser::Cache.global do |c|
      #     c.fetch_or_parse(content) { Parser::Base.parse(content) }
      #   end
      class Cache
        # Default maximum cache size
        DEFAULT_MAX_SIZE = 50

        # Get the global cache instance
        # @return [Cache, nil] The global cache instance
        def self.global
          @global ||= nil
        end

        # Set the global cache instance
        # @param cache [Cache, nil] The cache instance
        class << self
          attr_writer :global
        end

        # Execute a block with a global cache
        # @param max_size [Integer] Maximum cache entries
        # @yield [Cache] The cache instance
        # @return [Object] The block result
        def self.with_global(max_size: DEFAULT_MAX_SIZE)
          previous = @global
          @global = new(max_size: max_size)
          begin
            yield @global
          ensure
            @global = previous
          end
        end

        # Clear the global cache
        def self.clear_global!
          @global&.clear
        end

        # Initialize a new cache
        # @param max_size [Integer] Maximum number of entries to cache
        def initialize(max_size: DEFAULT_MAX_SIZE)
          @max_size = max_size
          @cache = {}
          @access_order = []
          @mutex = Mutex.new
        end

        # Fetch a cached result or parse and cache
        #
        # @param content [String] The content to parse
        # @yield Block to execute if cache miss
        # @return [Object] The parsed AST
        def fetch_or_parse(content)
          key = content_hash(content)

          mutex.synchronize do
            if cache.key?(key)
              # Move to end of access order (most recently used)
              access_order.delete(key)
              access_order.push(key)
              return cache[key]
            end
          end

          # Parse outside the lock for concurrency
          result = yield if block_given?

          mutex.synchronize do
            # Evict oldest if at capacity
            evict_oldest if cache.size >= max_size

            cache[key] = result
            access_order.push(key)
          end

          result
        end

        # Check if content is cached
        # @param content [String] The content to check
        # @return [Boolean] True if cached
        def cached?(content)
          key = content_hash(content)
          mutex.synchronize { cache.key?(key) }
        end

        # Get cache statistics
        # @return [Hash] Statistics including size, max_size, hits, misses
        def stats
          mutex.synchronize do
            {
              size: cache.size,
              max_size: max_size,
              keys: access_order.dup
            }
          end
        end

        # Clear the cache
        def clear
          mutex.synchronize do
            cache.clear
            access_order.clear
          end
        end

        # Get the current cache size
        # @return [Integer] Number of cached entries
        def size
          mutex.synchronize { cache.size }
        end

        private

        attr_reader :cache, :max_size, :access_order, :mutex

        # Generate a hash key for content
        # @param content [String] The content
        # @return [String] SHA256 hash of content
        def content_hash(content)
          Digest::SHA256.hexdigest(content)
        end

        # Evict the oldest (least recently used) entry
        def evict_oldest
          return if access_order.empty?

          oldest_key = access_order.shift
          cache.delete(oldest_key)
        end
      end
    end
  end
end

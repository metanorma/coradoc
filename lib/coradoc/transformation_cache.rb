# frozen_string_literal: true

module Coradoc
  # Transformation caching for improved performance.
  #
  # Provides caching for transformation results to avoid redundant
  # processing when the same content is transformed multiple times.
  #
  # @example Basic usage
  #   cache = Coradoc::TransformationCache.new
  #   result = cache.fetch(document, format: :asciidoc, to: :html) do
  #     transform_document(document)
  #   end
  #
  # @example With configuration
  #   cache = Coradoc::TransformationCache.new(
  #     max_size: 1000,
  #     ttl: 3600  # 1 hour
  #   )
  #
  module TransformationCache
    # Cache entry with metadata
    class Entry
      # @return [Object] Cached value
      attr_reader :value

      # @return [Time] When entry was created
      attr_reader :created_at

      # @return [Integer] Size in bytes (approximate)
      attr_reader :size

      # @return [String] Content hash for validation
      attr_reader :content_hash

      # Create a cache entry
      #
      # @param value [Object] Value to cache
      # @param content_hash [String] Hash of source content
      def initialize(value, content_hash)
        @value = value
        @content_hash = content_hash
        @created_at = Time.now
        @size = estimate_size(value)
      end

      # Check if entry has expired
      #
      # @param ttl [Integer] Time-to-live in seconds (0 = no expiry)
      # @return [Boolean]
      def expired?(ttl)
        return false if ttl.zero?

        Time.now - @created_at > ttl
      end

      # Check if content hash matches
      #
      # @param hash [String] Content hash to compare
      # @return [Boolean]
      def matches?(hash)
        @content_hash == hash
      end

      private

      # Estimate size of cached value
      def estimate_size(value)
        case value
        when String
          value.bytesize
        when Array
          value.sum { |v| estimate_size(v) }
        when Hash
          value.sum { |k, v| k.to_s.bytesize + estimate_size(v) }
        else
          value.to_s.bytesize
        end
      end
    end

    # In-memory cache backend
    class MemoryBackend
      # @return [Integer] Maximum entries
      attr_reader :max_size

      # @return [Integer] TTL in seconds
      attr_reader :ttl

      # Create a memory cache backend
      #
      # @param max_size [Integer] Maximum number of entries
      # @param ttl [Integer] Time-to-live in seconds
      def initialize(max_size: 1000, ttl: 0)
        @max_size = max_size
        @ttl = ttl
        @cache = {}
        @access_order = []
        @mutex = Mutex.new
      end

      # Get a cached value
      #
      # @param key [String] Cache key
      # @return [Entry, nil] Cache entry or nil
      def get(key)
        @mutex.synchronize do
          entry = @cache[key]
          return nil if entry.nil?
          return nil if entry.expired?(@ttl)

          # Update access order (LRU)
          @access_order.delete(key)
          @access_order.push(key)

          entry
        end
      end

      # Set a cached value
      #
      # @param key [String] Cache key
      # @param entry [Entry] Cache entry
      # @return [void]
      def set(key, entry)
        @mutex.synchronize do
          # Evict if at capacity
          evict_lru while @cache.size >= @max_size

          @cache[key] = entry
          @access_order.push(key)
        end
      end

      # Delete a cached value
      #
      # @param key [String] Cache key
      # @return [Boolean] True if deleted
      def delete(key)
        @mutex.synchronize do
          @access_order.delete(key)
          @cache.delete(key) ? true : false
        end
      end

      # Clear all cached values
      #
      # @return [void]
      def clear
        @mutex.synchronize do
          @cache.clear
          @access_order.clear
        end
      end

      # Get cache statistics
      #
      # @return [Hash] Statistics
      def stats
        @mutex.synchronize do
          total_size = @cache.values.sum(&:size)
          {
            entries: @cache.size,
            max_size: @max_size,
            total_bytes: total_size,
            ttl: @ttl
          }
        end
      end

      # Check if key exists
      #
      # @param key [String] Cache key
      # @return [Boolean]
      def key?(key)
        @mutex.synchronize do
          entry = @cache[key]
          return false if entry.nil?
          return false if entry.expired?(@ttl)

          true
        end
      end

      private

      # Evict least recently used entry
      def evict_lru
        return if @access_order.empty?

        key = @access_order.shift
        @cache.delete(key)
      end
    end

    # File-based cache backend
    class FileBackend
      # @return [String] Cache directory
      attr_reader :cache_dir

      # @return [Integer] Maximum cache size in bytes
      attr_reader :max_bytes

      # @return [Integer] TTL in seconds
      attr_reader :ttl

      # Create a file cache backend
      #
      # @param cache_dir [String] Directory for cache files
      # @param max_bytes [Integer] Maximum total cache size
      # @param ttl [Integer] Time-to-live in seconds
      def initialize(cache_dir:, max_bytes: 100 * 1024 * 1024, ttl: 0)
        @cache_dir = cache_dir
        @max_bytes = max_bytes
        @ttl = ttl
        @mutex = Mutex.new

        ensure_cache_dir
      end

      # Get a cached value
      #
      # @param key [String] Cache key
      # @return [Entry, nil] Cache entry or nil
      def get(key)
        path = cache_path(key)
        return nil unless File.exist?(path)

        @mutex.synchronize do
          data = File.binread(path)
          entry = Marshal.load(data)

          return nil if entry.expired?(@ttl)

          entry
        rescue StandardError
          nil
        end
      end

      # Set a cached value
      #
      # @param key [String] Cache key
      # @param entry [Entry] Cache entry
      # @return [void]
      def set(key, entry)
        path = cache_path(key)

        @mutex.synchronize do
          File.binwrite(path, Marshal.dump(entry))
        end
      end

      # Delete a cached value
      #
      # @param key [String] Cache key
      # @return [Boolean] True if deleted
      def delete(key)
        path = cache_path(key)

        @mutex.synchronize do
          File.delete(path) if File.exist?(path)
        end
      rescue StandardError
        false
      end

      # Clear all cached values
      #
      # @return [void]
      def clear
        @mutex.synchronize do
          Dir.glob(File.join(@cache_dir, '*.cache')).each do |path|
            File.delete(path)
          rescue StandardError
            nil
          end
        end
      end

      # Get cache statistics
      #
      # @return [Hash] Statistics
      def stats
        @mutex.synchronize do
          files = Dir.glob(File.join(@cache_dir, '*.cache'))
          total_bytes = files.sum do |f|
            File.size(f)
          rescue StandardError
            0
          end

          {
            entries: files.size,
            max_bytes: @max_bytes,
            total_bytes: total_bytes,
            ttl: @ttl
          }
        end
      end

      # Check if key exists
      #
      # @param key [String] Cache key
      # @return [Boolean]
      def key?(key)
        path = cache_path(key)
        return false unless File.exist?(path)

        entry = get(key)
        !entry.nil?
      end

      private

      def cache_path(key)
        # Use hash of key for filename to handle special characters
        hashed_key = Digest::SHA256.hexdigest(key)
        File.join(@cache_dir, "#{hashed_key}.cache")
      end

      def ensure_cache_dir
        Dir.mkdir(@cache_dir) unless Dir.exist?(@cache_dir)
      end
    end

    # Cache key generator
    class KeyGenerator
      # Generate a cache key for transformation
      #
      # @param source [Object] Source object
      # @param options [Hash] Transformation options
      # @return [String] Cache key
      def self.generate(source, options = {})
        parts = [
          content_hash(source),
          options[:from]&.to_s,
          options[:to]&.to_s,
          options[:format]&.to_s,
          options[:transformer]&.to_s
        ].compact

        Digest::SHA256.hexdigest(parts.join(':'))
      end

      # Generate hash of content
      #
      # @param content [Object] Content to hash
      # @return [String] Content hash
      def self.content_hash(content)
        case content
        when String
          Digest::SHA256.hexdigest(content)
        when Array
          Digest::SHA256.hexdigest(content.map { |c| content_hash(c) }.join)
        when Hash
          hash_content = content.sort.map { |k, v| "#{k}=#{content_hash(v)}" }.join
          Digest::SHA256.hexdigest(hash_content)
        else
          # For objects, hash their string representation
          Digest::SHA256.hexdigest(content.to_s)
        end
      end
    end

    class << self
      # Get the global cache instance
      #
      # @return [MemoryBackend, FileBackend] Cache backend
      def cache
        @cache ||= MemoryBackend.new(
          max_size: Coradoc.config.cache.max_size,
          ttl: Coradoc.config.cache.ttl
        )
      end

      # Set a custom cache backend
      #
      # @param backend [MemoryBackend, FileBackend] Cache backend
      # @return [void]
      attr_writer :cache

      # Fetch from cache or compute
      #
      # @param source [Object] Source object to transform
      # @param options [Hash] Transformation options
      # @yield Block to compute value if not cached
      # @return [Object] Cached or computed value
      def fetch(source, options = {})
        return yield unless Coradoc.config.cache.enabled

        key = KeyGenerator.generate(source, options)
        entry = cache.get(key)

        if entry
          content_hash = KeyGenerator.content_hash(source)
          return entry.value if entry.matches?(content_hash)
        end

        # Compute and cache
        value = yield
        content_hash = KeyGenerator.content_hash(source)
        cache.set(key, Entry.new(value, content_hash))

        value
      end

      # Clear the cache
      #
      # @return [void]
      def clear
        cache.clear
      end

      # Get cache statistics
      #
      # @return [Hash] Cache statistics
      def stats
        cache.stats
      end

      # Create a file-based cache
      #
      # @param cache_dir [String] Directory for cache files
      # @param max_bytes [Integer] Maximum cache size in bytes
      # @param ttl [Integer] TTL in seconds
      # @return [FileBackend] File cache backend
      def create_file_cache(cache_dir, max_bytes: 100 * 1024 * 1024, ttl: 0)
        FileBackend.new(cache_dir: cache_dir, max_bytes: max_bytes, ttl: ttl)
      end

      # Use file-based cache
      #
      # @param cache_dir [String] Directory for cache files
      # @param max_bytes [Integer] Maximum cache size in bytes
      # @param ttl [Integer] TTL in seconds
      # @return [void]
      def use_file_cache!(cache_dir, max_bytes: 100 * 1024 * 1024, ttl: 0)
        @cache = create_file_cache(cache_dir, max_bytes: max_bytes, ttl: ttl)
      end
    end
  end
end

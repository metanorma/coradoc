# frozen_string_literal: true

require 'pathname'

module Coradoc
  class IncludeResolver
    # Default include resolver: reads files from the local filesystem,
    # rooted at +base_dir+. Path-traversal protection is ON by default
    # to match asciidoctor's +:safe+ mode.
    #
    # Pass +allow_unsafe: true+ to opt out (matches +:unsafe+ mode).
    class Filesystem < IncludeResolver
      attr_reader :base_dir, :allow_unsafe, :max_bytes

      # @param base_dir [String] absolute path to the directory includes
      #   are resolved against. Usually the directory of the including
      #   document. Relative paths inside the resolver are expanded
      #   against this.
      # @param allow_unsafe [Boolean] when false (default), refuses any
      #   resolved path that escapes +base_dir+ via .. or that is an
      #   absolute path outside +base_dir+.
      # @param max_bytes [Integer, nil] if set, refuses files larger
      #   than this. Defense against accidental megabyte-include loops.
      def initialize(base_dir:, allow_unsafe: false, max_bytes: nil)
        @base_dir = File.expand_path(base_dir)
        @allow_unsafe = allow_unsafe
        @max_bytes = max_bytes
      end

      def call(target:, base_dir:, options:, context:)
        full = File.expand_path(target, base_dir)
        enforce_safety!(full, base_dir) unless allow_unsafe
        raise Coradoc::IncludeNotFoundError, target unless File.file?(full)

        enforce_size!(full, target)

        encoding = options&.file_encoding || 'utf-8'
        read_with_encoding(full, encoding)
      end

      private

      def enforce_safety!(full_path, base_dir)
        base_expanded = File.expand_path(base_dir)
        base_with_sep = "#{base_expanded}#{File::SEPARATOR}"

        return if full_path == base_expanded || full_path.start_with?(base_with_sep)

        raise Coradoc::UnsafeIncludeError, full_path
      end

      def enforce_size!(full_path, target)
        return unless max_bytes
        return unless File.exist?(full_path)

        size = File.size(full_path)
        return if size <= max_bytes

        raise Coradoc::IncludeTooLargeError, target
      end

      def read_with_encoding(full_path, encoding_name)
        content = File.binread(full_path)
        return content if encoding_name.to_s.downcase == 'binary'

        content.force_encoding(clean_encoding_name(encoding_name))
        encoded = content.encode('utf-8', invalid: :replace, undef: :replace)
        normalize_line_endings(encoded)
      rescue ArgumentError => e
        raise Coradoc::Error, "Unsupported encoding #{encoding_name.inspect}: #{e.message}"
      end

      # asciidoctor parity: normalize CRLF and lone CR to LF so the parser
      # sees consistent line endings regardless of the source platform.
      def normalize_line_endings(text)
        text.gsub(/\r\n?/, "\n")
      end

      def clean_encoding_name(name)
        name.to_s.downcase.sub(/^utf-8$/, 'utf-8')
      end
    end
  end
end

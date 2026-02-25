# frozen_string_literal: true

require 'fileutils'

module Coradoc
  module AsciiDoc
    module Model
      # Resolver classes for handling external document references.
      #
      # The resolver infrastructure provides a unified way to handle different
      # types of external references (includes, images, media) with configurable
      # resolution strategies.
      #
      # @example Resolving includes only
      #   resolver = Resolver.new(includes: true, images: :reference, media: :reference)
      #   resolved = resolver.resolve_document(doc, base_dir)
      #
      # @example Creating a self-contained document
      #   resolver = Resolver.new(
      #     includes: true,
      #     images: :embed,
      #     media: :copy,
      #     output_dir: "/path/to/output"
      #   )
      #   resolved = resolver.resolve_document(doc, base_dir)
      #
      class Resolver
        # @return [IncludeResolver, nil] the include resolver (nil if disabled)
        attr_reader :include_resolver

        # @return [ImageResolver] the image resolver
        attr_reader :image_resolver

        # @return [MediaResolver] the media resolver
        attr_reader :media_resolver

        # @return [String, nil] the output directory for copied files
        attr_reader :output_dir

        # Create a new Resolver with specified options.
        #
        # @param options [Hash] resolution options
        # @option options [Boolean] :includes Whether to resolve include directives
        # @option options [Symbol] :images Image resolution strategy (:reference, :copy, :embed)
        # @option options [Symbol] :media Media resolution strategy (:reference, :copy, :embed)
        # @option options [String] :output_dir Output directory for :copy mode
        # @option options [Integer] :max_recursion Maximum recursion depth for includes
        #
        def initialize(options = {})
          @include_resolver = options[:includes] ? IncludeResolver.new : nil
          @image_resolver = ImageResolver.new(strategy: options[:images] || :reference)
          @media_resolver = MediaResolver.new(strategy: options[:media] || :reference)
          @output_dir = options[:output_dir]
          @max_recursion = options[:max_recursion] || 10
          @resolved_paths = {} # Track resolved paths to prevent infinite recursion
        end

        # Resolve a single node.
        #
        # @param node [Base] the node to resolve
        # @param base_dir [String] base directory for relative paths
        # @param depth [Integer] current recursion depth
        # @return [Base, Array<Base>] the resolved node(s)
        #
        def resolve(node, base_dir, depth = 0)
          return node if depth > @max_recursion

          case node
          when Include
            resolve_include(node, base_dir, depth)
          when Image::BlockImage, Image::InlineImage
            resolve_image(node, base_dir)
          when Video
            resolve_media(node, base_dir, :video)
          when Audio
            resolve_media(node, base_dir, :audio)
          else
            node
          end
        end

        # Resolve an entire document.
        #
        # @param document [Document] the document to resolve
        # @param base_dir [String] base directory for relative paths
        # @return [Document] a NEW document with resolved references
        #
        def resolve_document(document, base_dir)
          resolved_sections = document.sections.map do |section|
            resolve_node_recursive(section, base_dir, 0)
          end.flatten.compact

          document.class.new(
            document_attributes: document.document_attributes,
            header: document.header,
            sections: resolved_sections
          )
        end

        private

        def resolve_include(include_node, base_dir, depth)
          return [include_node] unless @include_resolver

          path = include_node.reference_path
          full_path = File.expand_path(path, base_dir)

          # Check for recursion
          if @resolved_paths[full_path]
            warn "[Coradoc] Warning: Circular include detected: #{path}"
            return [include_node]
          end

          @resolved_paths[full_path] = true

          result = @include_resolver.resolve(include_node, base_dir)

          # Recursively resolve the included content
          if result.is_a?(Array)
            result.map { |node| resolve_node_recursive(node, File.dirname(full_path), depth + 1) }.flatten
          else
            resolve_node_recursive(result, File.dirname(full_path), depth + 1)
          end
        ensure
          @resolved_paths.delete(full_path) if full_path
        end

        def resolve_image(image_node, base_dir)
          @image_resolver.resolve(image_node, base_dir, @output_dir)
        end

        def resolve_media(media_node, base_dir, _type)
          @media_resolver.resolve(media_node, base_dir, @output_dir)
        end

        def resolve_node_recursive(node, base_dir, depth)
          return node if depth > @max_recursion

          resolved = resolve(node, base_dir, depth)

          # If resolution returns an array (e.g., expanded includes), process each
          return resolved.map { |n| resolve_node_recursive(n, base_dir, depth) }.flatten if resolved.is_a?(Array)

          # Handle nodes with nested content
          if resolved.respond_to?(:contents) && resolved.contents
            resolved = deep_copy_node(resolved)
            resolved.contents = resolved.contents.map do |child|
              resolve_node_recursive(child, base_dir, depth + 1)
            end.flatten.compact
          end

          # Handle sections with nested content
          if resolved.respond_to?(:sections) && resolved.sections && !resolved.is_a?(Document)
            resolved = deep_copy_node(resolved)
            resolved.sections = resolved.sections.map do |child|
              resolve_node_recursive(child, base_dir, depth + 1)
            end.flatten.compact
          end

          resolved
        end

        def deep_copy_node(node)
          # Create a new instance with the same attributes
          node.class.new(node.to_h)
        rescue StandardError
          # If to_h doesn't work, return the original node
          node
        end
      end

      # Resolves include directives by parsing and including file contents.
      class IncludeResolver
        # Resolve an include directive.
        #
        # @param include_node [Include] the include directive
        # @param base_dir [String] base directory for relative paths
        # @return [Array<Base>, Include] the included content or original node if not found
        #
        def resolve(include_node, base_dir)
          path = include_node.reference_path
          full_path = File.expand_path(path, base_dir)

          unless File.exist?(full_path)
            warn "[Coradoc] Warning: Include file not found: #{path}"
            return [include_node]
          end

          content = File.read(full_path)

          # Apply include options (lines, tags, etc.)
          content = apply_include_options(content, include_node.reference_options)

          # Parse the included content
          included_doc = Coradoc::AsciiDoc.parse(content)

          # Return the sections from the included document
          included_doc.sections || []
        end

        private

        def apply_include_options(content, options)
          return content if options.empty?

          lines = content.lines

          # Apply lines filter
          if options[:lines]
            range_match = options[:lines].match(/(\d+)\.\.(\d+)/)
            if range_match
              start_line = [1, range_match[1].to_i].max
              end_line = [lines.length, range_match[2].to_i].min
              lines = lines[(start_line - 1)...end_line] || []
            end
          end

          # Apply tags filter
          lines = filter_by_tags(lines, options[:tags]) if options[:tags]

          lines.join
        end

        def filter_by_tags(lines, tags)
          # Simple tag filtering - find lines between tag markers
          result = []
          in_tag = false
          current_tags = []

          lines.each do |line|
            # Check for tag start: // tag::tagname[]
            if line =~ %r{//\s*tag::(\w+)\[\]}
              tag_name = Regexp.last_match(1)
              if tags.include?(tag_name)
                in_tag = true
                current_tags << tag_name
              end
              next
            end

            # Check for tag end: // end::tagname[]
            if line =~ %r{//\s*end::(\w+)\[\]}
              tag_name = Regexp.last_match(1)
              if current_tags.include?(tag_name)
                current_tags.delete(tag_name)
                in_tag = false if current_tags.empty?
              end
              next
            end

            result << line if in_tag
          end

          result
        end
      end

      # Resolves image references with configurable strategies.
      class ImageResolver
        # @return [Symbol] the resolution strategy
        attr_reader :strategy

        # Create a new ImageResolver.
        #
        # @param strategy [Symbol] resolution strategy (:reference, :copy, :embed)
        #
        def initialize(strategy: :reference)
          @strategy = strategy
        end

        # Resolve an image reference.
        #
        # @param image_node [Image::Core] the image node
        # @param base_dir [String] base directory for relative paths
        # @param output_dir [String, nil] output directory for :copy mode
        # @return [Image::Core] the resolved image node
        #
        def resolve(image_node, base_dir, output_dir = nil)
          case strategy
          when :reference
            image_node
          when :copy
            copy_image(image_node, base_dir, output_dir)
          when :embed
            embed_image(image_node, base_dir)
          else
            image_node
          end
        end

        private

        def copy_image(image_node, base_dir, output_dir)
          return image_node unless output_dir

          src = image_node.src
          return image_node if src.nil? || src.start_with?('data:')

          full_path = File.expand_path(src, base_dir)

          unless File.exist?(full_path)
            warn "[Coradoc] Warning: Image file not found: #{src}"
            return image_node
          end

          # Create images subdirectory in output
          images_dir = File.join(output_dir, 'images')
          FileUtils.mkdir_p(images_dir)

          # Copy the file
          dest_path = File.join(images_dir, File.basename(src))
          FileUtils.cp(full_path, dest_path)

          # Update the image node with new path
          new_node = image_node.class.new(image_node.to_h)
          new_node.src = "images/#{File.basename(src)}"
          new_node
        rescue StandardError => e
          warn "[Coradoc] Warning: Failed to copy image #{src}: #{e.message}"
          image_node
        end

        def embed_image(image_node, base_dir)
          src = image_node.src
          return image_node if src.nil? || src.start_with?('data:')

          full_path = File.expand_path(src, base_dir)

          unless File.exist?(full_path)
            warn "[Coradoc] Warning: Image file not found: #{src}"
            return image_node
          end

          # Read and encode the image
          image_data = File.read(full_path, mode: 'rb')
          base64_data = Base64.strict_encode64(image_data)

          # Determine MIME type from extension
          mime_type = mime_type_for(File.extname(src))

          # Create data URI
          data_uri = "data:#{mime_type};base64,#{base64_data}"

          # Update the image node
          new_node = image_node.class.new(image_node.to_h)
          new_node.src = data_uri
          new_node
        rescue StandardError => e
          warn "[Coradoc] Warning: Failed to embed image #{src}: #{e.message}"
          image_node
        end

        def mime_type_for(extension)
          case extension.downcase
          when '.png' then 'image/png'
          when '.jpg', '.jpeg' then 'image/jpeg'
          when '.gif' then 'image/gif'
          when '.svg' then 'image/svg+xml'
          when '.webp' then 'image/webp'
          else 'application/octet-stream'
          end
        end
      end

      # Resolves media (video/audio) references with configurable strategies.
      class MediaResolver
        # @return [Symbol] the resolution strategy
        attr_reader :strategy

        # Create a new MediaResolver.
        #
        # @param strategy [Symbol] resolution strategy (:reference, :copy)
        #
        def initialize(strategy: :reference)
          @strategy = strategy
        end

        # Resolve a media reference.
        #
        # @param media_node [Video, Audio] the media node
        # @param base_dir [String] base directory for relative paths
        # @param output_dir [String, nil] output directory for :copy mode
        # @return [Video, Audio] the resolved media node
        #
        def resolve(media_node, base_dir, output_dir = nil)
          case strategy
          when :reference
            media_node
          when :copy
            copy_media(media_node, base_dir, output_dir)
          else
            media_node
          end
        end

        private

        def copy_media(media_node, base_dir, output_dir)
          return media_node unless output_dir

          src = media_node.src
          return media_node if src.nil? || src.match?(%r{^[a-z][a-z0-9+.-]*://}i)

          full_path = File.expand_path(src, base_dir)

          unless File.exist?(full_path)
            warn "[Coradoc] Warning: Media file not found: #{src}"
            return media_node
          end

          # Create media subdirectory in output
          media_dir = File.join(output_dir, 'media')
          FileUtils.mkdir_p(media_dir)

          # Copy the file
          dest_path = File.join(media_dir, File.basename(src))
          FileUtils.cp(full_path, dest_path)

          # Update the media node with new path
          new_node = media_node.class.new(media_node.to_h)
          new_node.src = "media/#{File.basename(src)}"
          new_node
        rescue StandardError => e
          warn "[Coradoc] Warning: Failed to copy media #{src}: #{e.message}"
          media_node
        end
      end
    end
  end
end

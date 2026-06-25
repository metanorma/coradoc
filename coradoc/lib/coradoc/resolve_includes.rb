# frozen_string_literal: true

module Coradoc
  # Flat-mode include processor — the explicit "flatten" step.
  #
  # Walks a parsed CoreModel and expands every {CoreModel::Include} link
  # node into the parsed content of its target, recursing into the result.
  # The original CoreModel is NOT modified — a new subtree is constructed
  # and spliced into place.
  #
  # Invoked via the public API +Coradoc.resolve_includes(doc, base_dir:)+.
  # Callers control resolution strategy (filesystem, HTTP, custom),
  # missing-include policy, recursion depth, and path-traversal safety.
  #
  # Honors:
  #   - +missing_include+ policy: :error (default) | :warn | :silent | :passthrough
  #   - +max_depth+ limit (raises Coradoc::IncludeDepthExceededError)
  #   - circular detection (raises Coradoc::CircularIncludeError)
  #   - tags/lines/indent selectors (applied to raw text before parse)
  #   - leveloffset selector (applied to parsed CoreModel)
  #   - +base_dir+ re-rooting (recursive includes resolve relative to
  #     the including file — SPEC 7.2)
  class ResolveIncludes
    DEFAULT_MAX_DEPTH = 64

    class << self
      def call(core, resolver:, base_dir:, **opts)
        new(resolver: resolver, base_dir: base_dir, **opts).call(core)
      end
    end

    # @param resolver [#call] anything responding to +#call(target:, base_dir:, options:, context:)+
    # @param base_dir [String] absolute path to the document root directory
    # @param missing_include [Symbol] :error | :warn | :silent | :passthrough
    # @param max_depth [Integer] recursion cap
    # @param parse_format [Symbol] format to use when re-parsing included content
    def initialize(resolver:, base_dir:,
                   missing_include: :error,
                   max_depth: DEFAULT_MAX_DEPTH,
                   parse_format: :asciidoc)
      @resolver = Coradoc::IncludeResolver.coerce(resolver, base_dir: base_dir)
      @base_dir = base_dir
      @missing_policy = missing_include
      @max_depth = max_depth
      @parse_format = parse_format
    end

    # Walk + transform. Returns a NEW CoreModel with includes expanded.
    def call(core)
      expand_node(core, base_dir: File.expand_path(@base_dir), chain: [], depth: 0)
    end

    private

    def expand_node(node, base_dir:, chain:, depth:)
      return node unless node.is_a?(Coradoc::CoreModel::Base)

      case node
      when Coradoc::CoreModel::Include
        expand_include(node, base_dir: base_dir, chain: chain, depth: depth)
      when Coradoc::CoreModel::StructuralElement, Coradoc::CoreModel::Block
        expand_container(node, base_dir: base_dir, chain: chain, depth: depth)
      else
        node
      end
    end

    def expand_container(node, base_dir:, chain:, depth:)
      return node if node.children.nil? || node.children.empty?

      expanded_children = node.children.flat_map do |child|
        expanded = expand_node(child, base_dir: base_dir, chain: chain, depth: depth)
        Array(expanded)
      end

      return node if expanded_children.equal?(node.children) || same_children?(expanded_children, node.children)

      duplicate_with_children(node, expanded_children)
    end

    # The processor must not mutate its input. Each container that has
    # expanded includes is replaced by a shallow copy with a new
    # +children+ array — the original document tree stays intact so the
    # caller can re-resolve with different options.
    def duplicate_with_children(node, new_children)
      duplicate = node.dup
      duplicate.children = new_children
      duplicate
    end

    def same_children?(expanded, original)
      return false unless expanded.length == original.length

      expanded.each_with_index.all? { |node, i| node.equal?(original[i]) }
    end

    def expand_include(include_node, base_dir:, chain:, depth:)
      enforce_depth!(include_node, depth)
      enforce_cycle!(include_node, base_dir: base_dir, chain: chain)

      target = include_node.target
      new_chain = chain + [resolve_target_path(target, base_dir)]

      content = fetch_content(include_node, base_dir: base_dir)
      return replacement_for_missing(include_node) if missing_content?(content)

      applied = apply_text_selectors(content, include_node.options)
      parsed = parse_included(applied)

      shifted = Coradoc::IncludeSelectors::LevelOffset.call(parsed, options: include_node.options)

      new_base_dir = File.dirname(resolve_target_path(target, base_dir))
      expand_subtree(shifted, base_dir: new_base_dir, chain: new_chain, depth: depth + 1)
    end

    def missing_content?(content)
      content.nil? || content == :passthrough
    end

    def fetch_content(include_node, base_dir:)
      @resolver.call(
        target: include_node.target,
        base_dir: base_dir,
        options: include_node.options,
        context: {}
      )
    rescue Coradoc::IncludeNotFoundError => e
      handle_missing(include_node, e)
    end

    def handle_missing(include_node, error)
      case @missing_policy
      when :error then raise error
      when :warn
        Coradoc::Logger.warn("Include target not found: #{include_node.target}")
        nil
      when :silent then nil
      when :passthrough then :passthrough
      else raise error
      end
    end

    def replacement_for_missing(include_node)
      return [include_node] if @missing_policy == :passthrough

      []
    end

    def apply_text_selectors(text, options)
      text = apply_lines_or_tags(text, options)
      Coradoc::IncludeSelectors::Indent.call(text, options: options)
    end

    def apply_lines_or_tags(text, options)
      # lines wins when both specified (SPEC 3.5)
      return Coradoc::IncludeSelectors::Lines.call(text, options: options) if options.lines?

      Coradoc::IncludeSelectors::Tags.call(text, options: options)
    end

    def parse_included(text)
      return empty_core if text.nil? || text.empty?

      Coradoc.parse(text, format: @parse_format)
    end

    def empty_core
      Coradoc::CoreModel::DocumentElement.new
    end

    def expand_subtree(core, base_dir:, chain:, depth:)
      expanded = expand_node(core, base_dir: base_dir, chain: chain, depth: depth)
      return [expanded] unless expanded.is_a?(Coradoc::CoreModel::StructuralElement)

      expanded.children || []
    end

    def enforce_depth!(include_node, depth)
      return if depth < @max_depth

      raise Coradoc::IncludeDepthExceededError.new(
        target: include_node.target,
        depth: depth,
        max: @max_depth
      )
    end

    def enforce_cycle!(include_node, base_dir:, chain:)
      full = resolve_target_path(include_node.target, base_dir)
      return unless chain.include?(full)

      raise Coradoc::CircularIncludeError.new(
        target: include_node.target,
        chain: chain
      )
    end

    def resolve_target_path(target, base_dir)
      File.expand_path(target, base_dir)
    end
  end
end

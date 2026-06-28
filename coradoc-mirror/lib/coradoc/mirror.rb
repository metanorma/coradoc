# frozen_string_literal: true

require 'json'
require 'yaml'

module Coradoc
  module Mirror
    class Error < StandardError; end

    autoload :VERSION, "#{__dir__}/mirror/version"
    autoload :Node, "#{__dir__}/mirror/node"
    autoload :Mark, "#{__dir__}/mirror/mark"
    autoload :Transformer, "#{__dir__}/mirror/transformer"
    autoload :CoreModelToMirror, "#{__dir__}/mirror/core_model_to_mirror"
    autoload :MirrorToCoreModel, "#{__dir__}/mirror/mirror_to_core_model"
    autoload :Partitioner, "#{__dir__}/mirror/partitioner"
    # Shared tree→Hash translator for the frontmatter typed-tree. Read by
    # ReverseBuilder::Frontmatter and FrontmatterQuery — single source of
    # truth for the inverse of Handlers::Frontmatter.build_value.
    autoload :FrontmatterTreeToHash, "#{__dir__}/mirror/frontmatter_tree_to_hash"
    # Public read-API for downstream consumers (e.g. site generators) that
    # need a flat Ruby Hash of a Mirror doc's frontmatter without re-parsing
    # the source YAML. Frontmatter lives in the CoreModel and the Mirror
    # doc, not in a parallel YAML parse.
    autoload :FrontmatterQuery, "#{__dir__}/mirror/frontmatter_query"
    # ReverseBuilder's REGISTRY is populated by the built-in builder
    # subclasses (defined inside reverse_builder.rb) at load time. The
    # file is the autoload target, so the registry is full by the time
    # any caller references Coradoc::Mirror::ReverseBuilder.
    autoload :ReverseBuilder, "#{__dir__}/mirror/reverse_builder"
    # MarkReverseBuilder is the mark-level parallel to ReverseBuilder.
    # Same OCP pattern: one Builder class per mark type, self-registering.
    autoload :MarkReverseBuilder, "#{__dir__}/mirror/mark_reverse_builder"
    autoload :HandlerRegistry, "#{__dir__}/mirror/handler_registry"
    autoload :Handlers, "#{__dir__}/mirror/handlers"
    # MirrorJsonFormat and MirrorYamlFormat are loaded via require in
    # coradoc-mirror.rb (side-effect: register_format calls).

    # Build the default handler registry with all built-in handlers.
    #
    # Third-party code can add handlers to extend the registry without
    # modifying this method (OCP). Each handler maps a CoreModel class
    # to a handler module/class that produces Mirror nodes.
    #
    # @return [HandlerRegistry]
    def self.default_registry
      registry = HandlerRegistry.new

      # ── Structural ──
      registry.register(CoreModel::DocumentElement, Handlers::Structural,
                        method_name: :document)
      registry.register(CoreModel::SectionElement, Handlers::Structural,
                        method_name: :section)
      registry.register(CoreModel::PreambleElement, Handlers::Structural,
                        method_name: :preamble)
      registry.register(CoreModel::HeaderElement, Handlers::Structural,
                        method_name: :header)

      # ── Paragraphs ──
      registry.register(CoreModel::ParagraphBlock, Handlers::Paragraph)

      # ── Code / Preformatted ──
      registry.register(CoreModel::SourceBlock, Handlers::CodeBlock,
                        method_name: :source)
      registry.register(CoreModel::ListingBlock, Handlers::CodeBlock,
                        method_name: :listing)
      registry.register(CoreModel::LiteralBlock, Handlers::CodeBlock,
                        method_name: :literal)
      registry.register(CoreModel::PassBlock, Handlers::CodeBlock,
                        method_name: :pass)
      registry.register(CoreModel::StemBlock, Handlers::CodeBlock,
                        method_name: :stem)

      # ── Blocks ──
      registry.register(CoreModel::QuoteBlock, Handlers::Blockquote)
      registry.register(CoreModel::ExampleBlock, Handlers::Example)
      registry.register(CoreModel::SidebarBlock, Handlers::Sidebar)
      registry.register(CoreModel::AbstractBlock, Handlers::Abstract)
      registry.register(CoreModel::PartintroBlock, Handlers::Partintro)
      registry.register(CoreModel::OpenBlock, Handlers::OpenBlock)
      registry.register(CoreModel::VerseBlock, Handlers::Verse)
      registry.register(CoreModel::CommentBlock, Handlers::Comment)
      registry.register(CoreModel::HorizontalRuleBlock, Handlers::HorizontalRule)
      registry.register(CoreModel::ReviewerBlock, Handlers::Reviewer)

      # ── Annotations / Admonitions ──
      registry.register(CoreModel::AnnotationBlock, Handlers::Admonition)

      # ── Lists ──
      registry.register(CoreModel::ListBlock, Handlers::List)
      registry.register(CoreModel::DefinitionList, Handlers::DefinitionList)

      # ── Tables ──
      registry.register(CoreModel::Table, Handlers::Table)

      # ── Images ──
      registry.register(CoreModel::Image, Handlers::Image)

      # ── Inline ──
      registry.register(CoreModel::InlineElement, Handlers::Inline)
      registry.register(CoreModel::TextContent, Handlers::Inline,
                        method_name: :text_content)

      # ── Bibliography ──
      registry.register(CoreModel::Bibliography, Handlers::Bibliography)

      # ── Footnotes ──
      registry.register(CoreModel::Footnote, Handlers::Footnote)
      registry.register(CoreModel::FootnoteReference, Handlers::Footnote,
                        method_name: :reference)

      # ── TOC ──
      registry.register(CoreModel::Toc, Handlers::Toc)

      # ── Frontmatter ──
      registry.register(CoreModel::FrontmatterBlock, Handlers::Frontmatter)

      # ── Include directive (text-graph edge) ──
      registry.register(CoreModel::Include, Handlers::Include)

      # ── Generic Block (catch-all for unrecognized block types) ──
      registry.register(CoreModel::Block, Handlers::GenericBlock)

      registry
    end

    # Convenience: transform a CoreModel document to Mirror JSON in one call.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param registry [HandlerRegistry] handler registry (defaults to built-in)
    # @param partition_structural [Boolean] wrap doc.content in
    #   preface/sections/bibliography containers per the @metanorma/mirror JS
    #   structural contract (default: false for backward compatibility).
    # @return [Node::Document] mirror document root
    def self.transform(document, registry: default_registry, partition_structural: false)
      CoreModelToMirror.new(registry: registry).call(document, partition_structural: partition_structural)
    end

    # Convenience: transform and serialize to JSON string.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param pretty [Boolean] pretty-print JSON (default: false)
    # @param registry [HandlerRegistry] handler registry
    # @return [String] JSON string
    def self.to_json(document, pretty: false, registry: default_registry)
      node = transform(document, registry: registry)
      pretty ? JSON.pretty_generate(node.to_hash) : JSON.generate(node.to_hash)
    end

    # Convenience: transform and serialize to YAML string.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param registry [HandlerRegistry] handler registry
    # @return [String] YAML string
    def self.to_yaml(document, registry: default_registry)
      node = transform(document, registry: registry)
      YAML.dump(node.to_hash)
    end

    # Top-level hash dispatcher: reads `type` and delegates to the
    # matching Node subclass's lutaml-generated `from_hash`. This is a
    # module-level factory — the actual deserialization is done by
    # lutaml on the resolved subclass. Unknown types raise.
    #
    # @param hash [Hash, nil] wire-shape hash
    # @return [Node, nil]
    def self.from_hash(hash)
      return nil if hash.nil?

      type = hash.is_a?(Hash) ? hash['type'] : nil
      klass_name = Node::TYPE_TO_CLASS[type]
      raise Error, "Unknown mirror node type: #{type.inspect}" unless klass_name

      Object.const_get(klass_name).from_hash(hash)
    end
  end
end

# frozen_string_literal: true

require 'json'

module Coradoc
  module Mirror
    class Error < StandardError; end

    autoload :VERSION, "#{__dir__}/mirror/version"
    autoload :Node, "#{__dir__}/mirror/node"
    autoload :Mark, "#{__dir__}/mirror/mark"
    autoload :Transformer, "#{__dir__}/mirror/transformer"
    autoload :CoreModelToMirror, "#{__dir__}/mirror/core_model_to_mirror"
    autoload :MirrorToCoreModel, "#{__dir__}/mirror/mirror_to_core_model"
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

      # ── Blocks ──
      registry.register(CoreModel::QuoteBlock, Handlers::Blockquote)
      registry.register(CoreModel::ExampleBlock, Handlers::Example)
      registry.register(CoreModel::SidebarBlock, Handlers::Sidebar)
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

      # ── Generic Block (catch-all for unrecognized block types) ──
      registry.register(CoreModel::Block, Handlers::GenericBlock)

      registry
    end

    # Convenience: transform a CoreModel document to Mirror JSON in one call.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param registry [HandlerRegistry] handler registry (defaults to built-in)
    # @return [Node::Document] mirror document root
    def self.transform(document, registry: default_registry)
      CoreModelToMirror.new(registry: registry).call(document)
    end

    # Convenience: transform and serialize to JSON string.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param pretty [Boolean] pretty-print JSON (default: false)
    # @param registry [HandlerRegistry] handler registry
    # @return [String] JSON string
    def self.to_json(document, pretty: false, registry: default_registry)
      node = transform(document, registry: registry)
      node.to_json(pretty: pretty)
    end

    # Convenience: transform and serialize to YAML string.
    #
    # @param document [CoreModel::Base] CoreModel document
    # @param registry [HandlerRegistry] handler registry
    # @return [String] YAML string
    def self.to_yaml(document, registry: default_registry)
      node = transform(document, registry: registry)
      node.to_yaml
    end
  end
end

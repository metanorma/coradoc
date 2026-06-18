# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      # Per-document mutable state threaded through every serializer call,
      # AND the single dispatch interface element serializers use to
      # recurse into child elements.
      #
      # Threading dispatch through the context (not the runner) means
      # serializers stay stateless and don't need a back-reference to
      # the runner — they call `ctx.serialize(child)` and `ctx.serialize_inline(child)`.
      #
      # Holds counters (footnotes, link references) and accumulators
      # (footnote definitions emitted at document end, etc.). Created
      # fresh per top-level `call` — never shared between documents.
      class Context
        attr_reader :config, :registry, :runner,
                    :footnote_defs, :link_refs,
                    :footnote_counter, :link_counter

        def initialize(config:, registry:, runner:)
          @config = config
          @registry = registry
          @runner = runner
          @footnote_defs = []
          @link_refs = []
          @footnote_counter = 0
          @link_counter = 0
        end

        def serialize(element)
          runner.serialize(element, self)
        end

        def serialize_inline(element)
          runner.serialize_inline(element, self)
        end

        def serialize_inline_join(elements)
          Array(elements).map { |e| serialize_inline(e) }.join
        end

        def next_footnote_id
          @footnote_counter += 1
          "fn#{@footnote_counter}"
        end

        def next_link_ref_id
          @link_counter += 1
          @link_counter.to_s
        end

        def register_footnote_def(definition_text)
          @footnote_defs << definition_text unless @footnote_defs.include?(definition_text)
        end

        def register_link_ref(id, url, title: nil)
          @link_refs << LinkRef.new(id: id, url: url, title: title)
        end

        LinkRef = Struct.new(:id, :url, :title)
      end
    end
  end
end

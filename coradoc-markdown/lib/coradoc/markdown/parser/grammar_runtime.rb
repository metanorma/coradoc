# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module Markdown
    module Parser
      # Ruby-tier custom atoms for coradoc-markdown.parg: the parts of
      # the block grammar that need runtime state or Parslet result
      # shaping, which PARG expresses only as host-registered atoms.
      #
      # Each atom reproduces the matching DSL construct in
      # block_parser.rb exactly; grammar_parity_spec holds them to it.

      # Base for custom atoms. They read captures, so no result that
      # contains one may be memoized (same contract as Atoms::Dynamic).
      class GrammarAtom < Parsanol::Atoms::Custom
        def cached?
          false
        end

        def try(source, context, consume_all)
          context.mark_cache_unsafe!
          super
        end

        private

        def rule(name)
          Grammar.atom(name)
        end
      end

      # `X.ignore`: matches the named rule, yields nothing.
      module Ign
        class Base < GrammarAtom
          def try_match(source, context, _consume_all)
            ok, = rule(self.class::RULE).apply(source, context, false)
            ok ? [true, nil] : [false, nil]
          end
        end

        class LineEnding < Base; RULE = 'line_ending_raw'; end
        class BlankLine < Base; RULE = 'blank_line_raw'; end
        class WhitespaceRepeat < Base; RULE = 'whitespace_repeat'; end
        class ThematicChars < Base; RULE = 'thematic_break_chars'; end
        class ThematicInList < Base; RULE = 'thematic_break_in_list'; end
        class BlankLineVerbatim < Base; RULE = 'blank_line_verbatim'; end
      end

      # `.output(value)` fixed yields (Atoms::Constant in the DSL).
      module Const
        class Base < GrammarAtom
          def try_match(_source, _context, _consume_all)
            [true, self.class::VALUE]
          end
        end

        class Hr < Base; VALUE = { hr: true }.freeze; end
        class LnEmpty < Base; VALUE = { ln: '' }.freeze; end
        class Empty < Base; VALUE = ''; end
      end

      # Block nesting: the `scope`/`continuation`/`open_block` trio and
      # the fence-aware dynamic rules of the DSL grammar.
      module Nesting
        # Matches the innermost enclosing block's continuation (the
        # chain built by the scopes below), or "more input" at the top.
        class Continuation < GrammarAtom
          def try_match(source, context, _consume_all)
            captures = context.captures
            atom = captures.key?(:cont) ? captures[:cont] : rule('any_char_present')
            ok, = atom.apply(source, context, false)
            ok ? [true, nil] : [false, nil]
          end
        end

        # `scope { open_block(kind, cont) >> body }`: chains the new
        # block's continuation onto the enclosing one, then parses the
        # body rule inside the scope.
        class Scoped < GrammarAtom
          def try_match(source, context, _consume_all)
            context.scope do
              captures = context.captures
              own = continuation_atom
              captures[:cont] = captures.key?(:cont) ? captures[:cont] >> own : own
              captures[:block] = self.class::KIND
              ok, result = rule(self.class::BODY).apply(source, context, false)
              return ok ? [true, result] : [false, nil]
            end
          end
        end

        # `block_quote_cont`: a quote marker, or — only inside a
        # paragraph — a lazily continued line.
        class BlockQuoteContinuation < GrammarAtom
          def try_match(source, context, _consume_all)
            ok, result = rule('block_quote_marker').apply(source, context, false)
            return [true, result] if ok
            return [false, nil] unless context.captures[:block] == :paragraph

            rule('lazy_continuation').apply(source, context, false)
          end
        end

        class BlockQuoteScope < Scoped
          KIND = :block_quote
          BODY = 'block_quote_body'

          private

          def continuation_atom
            @continuation_atom ||= BlockQuoteContinuation.new
          end
        end

        class ParagraphScope < Scoped
          KIND = :paragraph
          BODY = 'paragraph_body'

          private

          def continuation_atom
            rule('paragraph_cont')
          end
        end

        # `code_fence_info`: backtick fences forbid backticks in the
        # info string.
        class FenceInfo < GrammarAtom
          def try_match(source, context, _consume_all)
            name = context.captures[:fence].to_s.chr == '`' ? 'fence_info_backtick' : 'fence_info_tilde'
            rule(name).apply(source, context, false)
          end
        end

        # `code_fence_close` body: the opening fence, then any run of
        # the fence character; yields nothing.
        class FenceClose < GrammarAtom
          def try_match(source, context, _consume_all)
            fence = context.captures[:fence].to_s
            atom = Parsanol::Atoms::Str.new(fence) >>
                   Parsanol::Atoms::Repetition.new(Parsanol::Atoms::Str.new(fence.chr), 0, nil, :repetition)
            ok, = atom.apply(source, context, false)
            ok ? [true, nil] : [false, nil]
          end
        end

        # Strips up to the fence's own indentation from content lines.
        class ConsumeFencedIndent < GrammarAtom
          def try_match(source, context, _consume_all)
            indent = context.captures[:fence_indent].to_s.length
            atom = if indent.positive?
                     Parsanol::Atoms::Repetition.new(Parsanol::Atoms::Str.new(' '), 0, indent, :repetition)
                   else
                     rule('any_char_present')
                   end
            atom.apply(source, context, false)
          end
        end
      end
    end
  end
end

require "parslet"
require "parslet/convenience"

module Coradoc
  module Parser
    module ParsletExtras
      refine Parslet::Scope do
        attr_reader :current

        def has_key?(...)
          @current.has_key?(...)
        end
      end

      refine Parslet::Scope::Binding do
        def has_key?(...)
          @hash.has_key?(...)
        end

        def initialize_copy(original)
          super
          @hash = @hash.clone
        end
      end

      # like Named but returning other things
      # NOTE: Parslet only accepts hashes and arrays
      class Output < Parslet::Atoms::Base
        attr_reader :parslet, :value
        def initialize(parslet, value)
          super()

          @parslet, @value = parslet, value
        end
  
        def apply(source, context, consume_all)
          success, _ = result = parslet.apply(source, context, consume_all)

          return result unless success
          succ(@value)
        end
  
        def to_s_inner(prec)
          "#{value}:#{parslet.to_s(prec)}"
        end
      end

      refine Parslet::Atoms::DSL do
        def output(value)
          Output.new(self, value)
        end
      end
    end

    class Markdown < Parslet::Parser
      using ParsletExtras

      def line_ending
        str("\n") | str("\r\n") | str("\r")
      end

      def debug(msg)
        dynamic do |src, ctx|
          puts "#{msg} @ #{src.line_and_column}:"
          pp ctx.captures
          any.present? | any.absent?
        end
      end

      rule(:non_indent_space) { str(" ").repeat(0, 3) }

      rule(:whitespace) { match[" \t"] }
      rule(:blank_line) { whitespace.repeat(1) >> any.absent? | whitespace.repeat >> line_ending }
      rule(:line_char) { match["^\r\n"] }
      rule(:line) { line_char.repeat(1).as(:ln) >> any.absent? | line_char.repeat.as(:ln) >> line_ending }

      # MUST NOT be a `rule`, otherwise gets cached in a failure state and prevents nested alternatives from working
      def continuation
        dynamic do |src, ctx|
          # puts "parsing continuation at #{src.line_and_column} (#{src.bytepos}) with #{ctx.captures[:cont]}"
          ctx.captures[:cont]
        end
      end

      def open_block(kind, cont_rule)
        dynamic do |src, ctx|
          parent_scope = ctx.captures.current.parent
          ctx.captures[:cont] = cont_rule
          ctx.captures[:cont] = parent_scope[:cont] >> cont_rule if parent_scope.has_key?(:cont)
          # puts "starting block #{kind} at #{src.line_and_column} (#{src.bytepos}): #{ctx.captures[:cont]}"
          any.present? | any.absent?
        end
      end

      rule(:atx_ending_seq) do
        whitespace.repeat(1) >> str("#").repeat >> whitespace.repeat >> line_ending.present?
      end

      rule(:atx_heading) do
        non_indent_space >> str("#").repeat(1, 6).as(:heading) >> str("#").absent? >>
        (
          # first check to catch only one space (that would be consumed with the repeat(1)) until ending seq
          atx_ending_seq.absent? >> str(" ").repeat(1) >> (atx_ending_seq.absent? >> line_char).repeat(1).as(:text)
        ).maybe >> atx_ending_seq.maybe >> line_ending
      end

      def thematic_break_char(c)
        (str(c) >> whitespace.repeat).repeat(3)
      end

      rule(:thematic_break) do
        non_indent_space >> (thematic_break_char("-") | thematic_break_char("_") | thematic_break_char("*")).output(hr: true) >> line_ending
      end

      # TODO: actually verbatim, not paragraph lines
      rule(:indented_code_block) do
        str("    ") >> scope do
          open_block(:indented_code, str("    ")) >> (line >> (continuation >> line).repeat).as(:code_block)
        end
      end

      rule(:block_quote_marker) do
        non_indent_space >> str(">") >> str(" ").maybe
      end

      rule(:block_quote) do
        block_quote_marker >> scope do
          open_block(:block_quote, block_quote_marker) >> (block >> (continuation >> block).repeat).as(:block_quote)
        end
      end

      rule(:paragraph_interrupt) do
        blank_line | atx_heading | thematic_break | block_quote
      end

      rule(:paragraph) do
        paragraph_interrupt.absent? >> scope do
          open_block(:paragraph, paragraph_interrupt.absent?) >> non_indent_space >> (line >> (continuation >> line).repeat).as(:p)
        end
      end

      rule(:block) do
        blank_line | atx_heading | thematic_break | indented_code_block | block_quote | paragraph
      end

      root :document
      rule(:document) do
        block.repeat
      end

      def self.parse(filename)
        content = File.read(filename)
        new.parse(content)
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'parslet_extras'
require_relative 'html_entities'

module Coradoc
  module Markdown
    module Parser
      class InlineParser < Parslet::Parser
        using ParsletExtras

        rule(:line_ending) { (str("\n") | str("\r\n") | str("\r")).ignore }
        rule(:line_ending_or_eof) { line_ending | any.absent? }
        rule(:whitespace) { match[" \t"] }
        rule(:unicode_whitespace) { match["\\p{Zs}\t\r\n\f"] | any.absent? }
        rule(:unicode_punctuation) { match['\\p{P}\\p{S}'] }

        def unicode_codepoint(base, s)
          i = s.to_s.to_i(base)
          return "\uFFFD" if i.zero?

          i.chr(Encoding::UTF_8)
        rescue RangeError
          "\uFFFD"
        end

        def unicode_dec(s)
          unicode_codepoint(10, s)
        end

        def unicode_hex(s)
          unicode_codepoint(16, s)
        end

        def lookup_entity(s)
          HTML_ENTITIES[s.to_s] || "&#{s};"
        end

        def process_code(s)
          s = s.to_s
          s.tr!("\n", ' ')
          return s.slice(1, s.length - 2) if s.length > 2 && s.start_with?(' ') && s.end_with?(' ')

          s
        end

        rule(:escape) { str('\\').ignore >> match["!\"#$%&'\\(\\)*+,\\-./:;<=>?@\\[\\\\\\]\\^_`\\{\\|\\}~"] }
        rule(:dec_entity) do
          str('&#').ignore >> match['0-9'].repeat(1, 7).dynamic_output(method(:unicode_dec)) >> str(';').ignore
        end
        rule(:hex_entity) do
          str('&#').ignore >> match['xX'].ignore >> match['A-Fa-f0-9'].repeat(1,
                                                                              6).dynamic_output(method(:unicode_hex)) >> str(';').ignore
        end
        rule(:entity) do
          str('&').ignore >> match['A-Za-z0-9'].repeat(1).dynamic_output(method(:lookup_entity)) >> str(';').ignore
        end
        rule(:nul_byte) { str("\0").output("\uFFFD") }
        rule(:special_char) { escape | dec_entity | hex_entity | entity | nul_byte }

        rule(:text) do
          (special_char | (element.absent? >> any)).repeat(1).as(:text)
        end

        rule(:code_span) do
          str('`').does_not_precede? >>
            str('`').repeat(1).capture(:code_opener).ignore >>
            dynamic do |_src, ctx|
              ending = (str('`').does_not_precede? >> str(ctx.captures[:code_opener]).ignore >> str('`').absent?)
              (ending.absent? >> any).repeat(1).dynamic_output(method(:process_code)).as(:code) >> ending
            end
        end

        rule(:delimiter_run) do
          str('*').repeat(1) | str('_').repeat(1)
        end

        rule(:both_flanking_delimiter_run) do
          any.precedes? >>
            unicode_whitespace.does_not_precede? >> (
            (
              unicode_punctuation.precedes? >>
              delimiter_run.as(:bfdr) >>
              unicode_punctuation.present?
            ) | (
              unicode_punctuation.does_not_precede? >>
              delimiter_run.as(:bfdr) >>
              unicode_punctuation.absent?
            )
          ) >> unicode_whitespace.absent?
        end

        rule(:left_flanking_delimiter_run) do
          (
            (
              delimiter_run.as(:lfdr) >>
              unicode_punctuation.absent?
            ) | (
              ((unicode_whitespace | unicode_punctuation).precedes? | any.does_not_precede?) >>
              delimiter_run.as(:lfdr)
            )
          ) >> unicode_whitespace.absent?
        end

        rule(:right_flanking_delimiter_run) do
          any.precedes? >>
            unicode_whitespace.does_not_precede? >> (
            (
              unicode_punctuation.precedes? >>
              delimiter_run.as(:rfdr) >>
              (unicode_whitespace | unicode_punctuation).present?
            ) | (
              unicode_punctuation.does_not_precede? >>
              delimiter_run.as(:rfdr)
            )
          )
        end

        rule(:non_flanking_delimiter_run) do
          left_flanking_delimiter_run.absent? >> left_flanking_delimiter_run.absent? >> delimiter_run.as(:nfdr)
        end

        rule(:flanking_delimiter_run) do
          both_flanking_delimiter_run | left_flanking_delimiter_run | right_flanking_delimiter_run | non_flanking_delimiter_run
        end

        rule(:run_surrounded_by_punctuation) do
          (unicode_punctuation.precedes? >> flanking_delimiter_run >> unicode_punctuation.present?).as(:rsp)
        end

        rule(:run_preceded_by_punctuation) do
          (unicode_punctuation.precedes? >> flanking_delimiter_run).as(:rpp)
        end

        rule(:run_followed_by_punctuation) do
          (flanking_delimiter_run >> unicode_punctuation.present?).as(:rfp)
        end

        rule(:checked_delimiter_run) do
          run_surrounded_by_punctuation | run_preceded_by_punctuation | run_followed_by_punctuation | flanking_delimiter_run
        end

        rule(:element) { code_span | checked_delimiter_run }

        rule(:inline) { (text | element).repeat }

        root :inline

        def can_open_emphasis(elem)
          return false unless elem[:left_flanking]
          return true unless elem[:char] == '_'

          !elem[:right_flanking] || (elem[:right_flanking] && elem[:preceded_by_punc])
        end

        def can_close_emphasis(elem)
          return false unless elem[:right_flanking]
          return true unless elem[:char] == '_'

          !elem[:left_flanking] || (elem[:left_flanking] && elem[:followed_by_punc])
        end

        def rule_of_three(opener, closer)
          return true unless (can_open_emphasis(opener) && can_close_emphasis(opener)) ||
                             (can_open_emphasis(closer) && can_close_emphasis(closer))

          ((opener[:length] % 3).zero? && (closer[:length] % 3).zero?) ||
            (opener[:length] + closer[:length]) % 3 != 0
        end

        def used_delims_to_text(elems)
          elems.map do |elem|
            if elem.key?(:char)
              next if elem[:length] < 1

              { text: elem[:char] * elem[:length] }
            else
              elem
            end
          end.compact
        end

        def build_delim_stack(tree)
          delim_stack = []
          tree.each_with_index do |elem, idx|
            next unless elem.is_a?(Hash) || elem.length != 1

            key = elem.first.first
            if %i[rsp rpp rfp].include?(key)
              outer_key = key
              tree[idx] = elem = elem[key]
              key = elem.first.first
            end
            next unless %i[bfdr lfdr rfdr nfdr].include?(key)

            delim_stack << idx
            # pp elem
            elem[:char] = elem[key].to_s[0]
            elem[:length] = elem[key].length
            elem[:left_flanking] = %i[bfdr lfdr].include?(key)
            elem[:right_flanking] = %i[bfdr rfdr].include?(key)
            elem[:preceded_by_punc] = %i[rsp rpp].include?(outer_key)
            elem[:followed_by_punc] = %i[rsp rfp].include?(outer_key)
            # elem[:active] = true
          end
          # pp delim_stack
          delim_stack
        end

        def process_emphasis(tree)
          delim_stack = build_delim_stack(tree)
          cur_pos = 0
          openers_bottom = { '*' => 0, '_' => 0 }
          while (closer_offset = delim_stack[cur_pos..].index { |i| can_close_emphasis(tree[i]) })
            # puts "-----"
            # pp tree
            # puts "clofset #{closer_offset} -> cur_pos #{closer_offset + cur_pos}"
            cur_pos += closer_offset
            closer = tree[closer_idx = delim_stack[cur_pos]]
            # puts "closer:#{cur_pos}, #{closer}"
            # look back - in reverse?
            opener_bottom = openers_bottom[closer[:char]]
            opener_to_cur = delim_stack.slice(opener_bottom, cur_pos - opener_bottom)
            # puts "obottom #{opener_bottom} len #{cur_pos - opener_bottom} -> opener_to_cur #{opener_to_cur}"
            opener_offset = (opener_to_cur || []).rindex do |i|
              can_open_emphasis(tree[i]) && tree[i][:char] == closer[:char] && rule_of_three(tree[i], closer)
            end
            # puts "opener:#{opener_offset}"
            if opener_offset
              opener = tree[opener_idx = delim_stack[opener_bottom + opener_offset]]
              strong = opener[:length] > 1 && closer[:length] > 1
              # pp opener
              contents_range = (opener_idx + 1)..(closer_idx - 1)
              # puts "crange #{contents_range} size #{contents_range.size}"
              contents = used_delims_to_text(tree.slice!(contents_range))
              tree.insert(opener_idx + 1, { (strong ? :strong : :emph) => contents })
              middle = (opener_bottom + opener_offset + 1)..(cur_pos - 1)
              delim_stack.slice!(middle)
              # puts "slice middle #{middle} -> #{delim_stack}"
              delim_stack.map! { |i| i <= opener_idx ? i : (i - contents_range.size + 1) }
              # puts "slice map <dstack.map!> #{delim_stack}"
              cur_pos -= middle.size
              if (opener[:length] -= strong ? 2 : 1).zero?
                delim_stack.slice!(opener_bottom + opener_offset)
                cur_pos -= 1
                # puts "slice opener #{opener_bottom + opener_offset} -> #{delim_stack} @#{cur_pos}"
              end
              if (closer[:length] -= strong ? 2 : 1).zero?
                delim_stack.slice!(cur_pos)
                # puts "slice closer #{cur_pos} -> #{delim_stack}"
              end
            else
              openers_bottom[closer[:chr]] = cur_pos - 1
              if can_open_emphasis(closer)
                cur_pos += 1
              else
                delim_stack.slice!(cur_pos)
                # puts "nopener slice #{cur_pos} -> #{delim_stack}"
              end
            end
          end
          # puts "----------"
          used_delims_to_text(tree)
          # puts "----------"
          # pp x
        end

        def parse(io, options = {})
          process_emphasis(super(io, options))
        end
      end
    end
  end
end

# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Item < Base
            HARDBREAK_MARKERS = %i[hardbreak init].freeze
            STRIP_UNICODE_BEGIN_MARKERS = (HARDBREAK_MARKERS.dup + [false]).freeze
            STRIP_UNICODE_END_MARKERS = [:hardbreak, :end, false].freeze

            def to_adoc(model, _options = {})
              @model = model
              _anchor = gen_anchor(inline: true)
              _content = Array(model.content).dup.flatten.compact
              out = ''
              prev_inline = :init

              # Collapse meaningless <DIV>s
              while _content.map(&:class) == [Coradoc::AsciiDoc::Model::Section] &&
                    _content.first.safe_to_collapse?

                _content = Array(_content.first.contents)
              end

              _content.each_with_index do |subitem, idx|
                subcontent = case subitem
                             when String
                               subitem
                             when Coradoc::AsciiDoc::Model::Base, Lutaml::Model::Serializable
                               subitem.to_adoc
                             else
                               if subitem.respond_to?(:to_adoc)
                                 subitem.to_adoc
                               else
                                 raise ArgumentError,
                                       "Cannot serialize list item content of type #{subitem.class.name}. " \
                                       'Expected String, Coradoc::AsciiDoc::Model::Base, or ' \
                                       "Lutaml::Model::Serializable. Got: #{subitem.inspect[0..100]}"
                               end
                             end

                inline = inline?(subitem)
                next_inline = idx + 1 == _content.length ? :end : inline?(_content[idx + 1])

                # Only try to postprocess elements that are text,
                # otherwise we could strip markup.
                if subitem.is_a?(Coradoc::AsciiDoc::Model::TextElement)
                  if STRIP_UNICODE_BEGIN_MARKERS.include?(prev_inline)
                    subcontent = Coradoc.strip_unicode(subcontent,
                                                       only: :begin)
                  end
                  if STRIP_UNICODE_END_MARKERS.include?(next_inline)
                    subcontent = Coradoc.strip_unicode(subcontent,
                                                       only: :end)
                  end
                end

                case inline
                when true
                  out += if prev_inline == false
                           "\n+\n#{subcontent}"
                         else
                           subcontent
                         end
                when false
                  out += case prev_inline
                         when :hardbreak
                           subcontent.strip
                         when :init
                           "{empty}\n+\n#{subcontent.strip}"
                         else
                           "\n+\n#{subcontent.strip}"
                         end
                when :hardbreak
                  if HARDBREAK_MARKERS.include?(prev_inline)
                    # can't have two hard breaks in a row
                    # can't start with a hard break
                  else
                    out += "\n+\n"
                  end
                end

                prev_inline = inline
              end
              out += '{empty}' if prev_inline == :hardbreak
              out = '{empty}' if out.empty?

              attach = model.attached.map do |elem|
                "+\n#{elem.to_adoc}"
              end.join
              nest = model.nested.nil? || (model.nested.respond_to?(:empty?) && model.nested.empty?) ? '' : model.nested.to_adoc
              out = " #{_anchor}#{out}#{model.line_break}"
              out + attach + nest
            end

            private

            def inline?(elem)
              case elem
              when Coradoc::AsciiDoc::Model::Inline::HardLineBreak
                :hardbreak
              when ->(i) { i.class.name.to_s.include?('::Inline::') }
                true
              when String, Coradoc::AsciiDoc::Model::TextElement, Coradoc::AsciiDoc::Model::Image::InlineImage
                true
              else
                false
              end
            end

            def gen_anchor(inline: false)
              return '' unless @model.anchor

              if inline
                @model.anchor.to_adoc.to_s
              else
                "#{@model.anchor.to_adoc}\n"
              end
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::Item, List::Item)
      end
    end
  end
end

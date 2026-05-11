# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Audio < Base
        def self.to_html(audio, _options = {})
          return '' unless audio

          src = audio.metadata&.dig(:src) || audio.content
          attrs = build_audio_attrs(audio)

          source_attrs = { src: src }
          type = build_type_attr(src)
          source_attrs[:type] = type if type

          source_node = NodeBuilder.build(:source, nil, **source_attrs)
          fallback = NodeBuilder.text('Your browser does not support the audio tag.')

          audio_node = NodeBuilder.build(:audio, [source_node, fallback], **attrs)

          if audio.title
            fig_attrs = {}
            fig_attrs[:id] = "#{audio.id}-figure" if audio.id
            caption = NodeBuilder.build(:figcaption, escape_html(audio.title))
            NodeBuilder.build(:figure, [audio_node, caption], **fig_attrs).to_html
          else
            audio_node.to_html
          end
        end

        def self.to_coradoc(element, _options = {})
          audio_elem = if element.name == 'figure'
                         element.at_css('audio')
                       elsif element.name == 'audio'
                         element
                       else
                         return nil
                       end

          return nil unless audio_elem

          src = extract_audio_src(audio_elem)
          return nil unless src

          caption = if element.name == 'figure'
                      figcaption = element.at_css('figcaption')
                      figcaption&.text&.strip
                    end

          metadata = extract_audio_metadata(audio_elem)
          metadata[:src] = src

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'audio',
            content: src,
            title: caption,
            id: audio_elem['id'] || element['id'],
            metadata: metadata
          )
        end

        def self.build_audio_attrs(audio)
          attrs = {}
          options = audio.metadata&.dig(:options) || []

          attrs[:controls] = '' unless options.include?('nocontrols')
          attrs[:autoplay] = '' if options.include?('autoplay')
          attrs[:loop] = '' if options.include?('loop')
          attrs[:muted] = '' if options.include?('muted')
          attrs[:id] = audio.id if audio.id

          attrs
        end

        def self.build_type_attr(src)
          ext = File.extname(src.to_s).downcase
          case ext
          when '.mp3' then 'audio/mpeg'
          when '.ogg', '.oga' then 'audio/ogg'
          when '.wav' then 'audio/wav'
          when '.m4a' then 'audio/mp4'
          when '.aac' then 'audio/aac'
          when '.flac' then 'audio/flac'
          end
        end

        def self.extract_audio_src(element)
          source = element.at_css('source')
          return source['src'] if source && source['src']

          element['src']
        end

        def self.extract_audio_metadata(element)
          metadata = {}
          options = []

          options << 'controls' if element.has_attribute?('controls')
          options << 'autoplay' if element.has_attribute?('autoplay')
          options << 'loop' if element.has_attribute?('loop')
          options << 'muted' if element.has_attribute?('muted')

          metadata[:options] = options unless options.empty?

          metadata
        end
      end
    end
  end
end

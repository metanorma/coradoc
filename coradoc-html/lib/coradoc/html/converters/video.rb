# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Video < Base
        def self.to_html(video, _options = {})
          return '' unless video

          src = video.metadata&.dig(:src) || video.content
          attrs = build_video_attrs(video)

          source_attrs = { src: src }
          type = build_type_attr(src)
          source_attrs[:type] = type if type

          source_node = NodeBuilder.build(:source, nil, **source_attrs)
          fallback = NodeBuilder.text('Your browser does not support the video tag.')

          video_node = NodeBuilder.build(:video, [source_node, fallback], **attrs)

          if video.title
            fig_attrs = {}
            fig_attrs[:id] = "#{video.id}-figure" if video.id
            caption = NodeBuilder.build(:figcaption, escape_html(video.title))
            NodeBuilder.build(:figure, [video_node, caption], **fig_attrs).to_html
          else
            video_node.to_html
          end
        end

        def self.to_coradoc(element, _options = {})
          video_elem = if element.name == 'figure'
                         element.at_css('video')
                       elsif element.name == 'video'
                         element
                       else
                         return nil
                       end

          return nil unless video_elem

          src = extract_video_src(video_elem)
          return nil unless src

          caption = if element.name == 'figure'
                      figcaption = element.at_css('figcaption')
                      figcaption&.text&.strip
                    end

          metadata = extract_video_metadata(video_elem)
          metadata[:src] = src

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'video',
            content: src,
            title: caption,
            id: video_elem['id'] || element['id'],
            metadata: metadata
          )
        end

        def self.build_video_attrs(video)
          attrs = {}
          options = video.metadata&.dig(:options) || []

          attrs[:controls] = '' unless options.include?('nocontrols')
          attrs[:autoplay] = '' if options.include?('autoplay')
          attrs[:loop] = '' if options.include?('loop')
          attrs[:muted] = '' if options.include?('muted')

          poster = video.metadata&.dig(:poster)
          attrs[:poster] = poster if poster

          width = video.metadata&.dig(:width)
          attrs[:width] = width if width

          height = video.metadata&.dig(:height)
          attrs[:height] = height if height

          attrs[:id] = video.id if video.id

          attrs
        end

        def self.build_type_attr(src)
          ext = File.extname(src.to_s).downcase
          case ext
          when '.mp4' then 'video/mp4'
          when '.webm' then 'video/webm'
          when '.ogg', '.ogv' then 'video/ogg'
          end
        end

        def self.extract_video_src(element)
          source = element.at_css('source')
          return source['src'] if source && source['src']

          element['src']
        end

        def self.extract_video_metadata(element)
          metadata = {}
          options = []

          options << 'controls' if element.has_attribute?('controls')
          options << 'autoplay' if element.has_attribute?('autoplay')
          options << 'loop' if element.has_attribute?('loop')
          options << 'muted' if element.has_attribute?('muted')

          metadata[:options] = options unless options.empty?
          metadata[:poster] = element['poster'] if element['poster']
          metadata[:width] = element['width'] if element['width']
          metadata[:height] = element['height'] if element['height']

          metadata
        end
      end
    end
  end
end

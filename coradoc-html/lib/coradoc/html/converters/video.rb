# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for video elements
      class Video < Base
        # Convert CoreModel::Block (video) to HTML <video>
        def self.to_html(video, _options = {})
          return '' unless video

          # Build video attributes
          attrs = build_attributes(video)

          # Get video source from metadata or content
          src = video.metadata&.dig(:src) || video.content

          # Build source element
          source_tag = %(<source src="#{escape_attribute(src)}"#{build_type_attr(src)}>)

          # Build optional caption/title
          caption = video.title

          # Determine if we need a wrapper (for block video with caption)
          if caption
            <<~HTML.strip
              <figure#{build_figure_attrs(video)}>
                <video#{attrs}>
                  #{source_tag}
                  Your browser does not support the video tag.
                </video>
                <figcaption>#{escape_html(caption)}</figcaption>
              </figure>
            HTML
          else
            <<~HTML.strip
              <video#{attrs}>
                #{source_tag}
                Your browser does not support the video tag.
              </video>
            HTML
          end
        end

        # Convert HTML <video> to CoreModel::Block (video)
        def self.to_coradoc(element, _options = {})
          # Handle both <video> and <figure><video> structures
          video_elem = if element.name == 'figure'
                         element.at_css('video')
                       elsif element.name == 'video'
                         element
                       else
                         return nil
                       end

          return nil unless video_elem

          # Extract source from <source> tag or src attribute
          src = extract_video_src(video_elem)
          return nil unless src

          # Extract caption if in figure
          caption = if element.name == 'figure'
                      figcaption = element.at_css('figcaption')
                      figcaption&.text&.strip
                    end

          # Extract ID if present
          id = video_elem['id'] || element['id']

          # Extract video attributes
          metadata = extract_video_metadata(video_elem)
          metadata[:src] = src

          Coradoc::CoreModel::Block.new(
            element_type: 'video',
            content: src,
            title: caption,
            id: id,
            metadata: metadata
          )
        end

        def self.build_attributes(video)
          attrs = []

          # Extract options from metadata
          options = video.metadata&.dig(:options) || []

          # Add controls by default (unless nocontrols option is set)
          has_controls = !options.include?('nocontrols')
          attrs << ' controls' if has_controls

          # Add autoplay if specified in options
          attrs << ' autoplay' if options.include?('autoplay')

          # Add loop if specified in options
          attrs << ' loop' if options.include?('loop')

          # Add muted if specified in options
          attrs << ' muted' if options.include?('muted')

          # Add poster if specified
          poster = video.metadata&.dig(:poster)
          attrs << %( poster="#{escape_attribute(poster)}") if poster

          # Add width and height if specified
          width = video.metadata&.dig(:width)
          height = video.metadata&.dig(:height)

          attrs << %( width="#{escape_attribute(width)}") if width

          attrs << %( height="#{escape_attribute(height)}") if height

          # Add ID if present
          attrs << %( id="#{escape_attribute(video.id)}") if video.id

          attrs.join
        end

        def self.build_type_attr(src)
          # Determine video MIME type from extension
          ext = File.extname(src).downcase
          type = case ext
                 when '.mp4'
                   'video/mp4'
                 when '.webm'
                   'video/webm'
                 when '.ogg', '.ogv'
                   'video/ogg'
                 end

          type ? %( type="#{type}") : ''
        end

        def self.build_figure_attrs(video)
          attrs = []

          # Add ID to figure if present
          attrs << %( id="#{escape_attribute(video.id)}-figure") if video.id

          attrs.join
        end

        def self.extract_video_src(element)
          # Try to get src from <source> tag first
          source = element.at_css('source')
          return source['src'] if source && source['src']

          # Fall back to src attribute on <video>
          element['src']
        end

        def self.extract_video_metadata(element)
          metadata = {}
          options = []

          # Extract boolean attributes
          options << 'controls' if element.has_attribute?('controls')
          options << 'autoplay' if element.has_attribute?('autoplay')
          options << 'loop' if element.has_attribute?('loop')
          options << 'muted' if element.has_attribute?('muted')

          metadata[:options] = options unless options.empty?

          # Extract poster
          metadata[:poster] = element['poster'] if element['poster']

          # Extract dimensions
          metadata[:width] = element['width'] if element['width']

          metadata[:height] = element['height'] if element['height']

          metadata
        end
      end
    end
  end
end

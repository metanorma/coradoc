# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for audio elements
      class Audio < Base
        # Convert CoreModel::Block (audio) to HTML <audio>
        def self.to_html(audio, _options = {})
          return '' unless audio

          # Build audio attributes
          attrs = build_attributes(audio)

          # Get audio source from metadata or content
          src = audio.metadata&.dig(:src) || audio.content

          # Build source element
          source_tag = %(<source src="#{escape_attribute(src)}"#{build_type_attr(src)}>)

          # Build optional caption/title
          caption = audio.title

          # Determine if we need a wrapper (for block audio with caption)
          if caption
            <<~HTML.strip
              <figure#{build_figure_attrs(audio)}>
                <audio#{attrs}>
                  #{source_tag}
                  Your browser does not support the audio tag.
                </audio>
                <figcaption>#{escape_html(caption)}</figcaption>
              </figure>
            HTML
          else
            <<~HTML.strip
              <audio#{attrs}>
                #{source_tag}
                Your browser does not support the audio tag.
              </audio>
            HTML
          end
        end

        # Convert HTML <audio> to CoreModel::Block (audio)
        def self.to_coradoc(element, _options = {})
          # Handle both <audio> and <figure><audio> structures
          audio_elem = if element.name == 'figure'
                         element.at_css('audio')
                       elsif element.name == 'audio'
                         element
                       else
                         return nil
                       end

          return nil unless audio_elem

          # Extract source from <source> tag or src attribute
          src = extract_audio_src(audio_elem)
          return nil unless src

          # Extract caption if in figure
          caption = if element.name == 'figure'
                      figcaption = element.at_css('figcaption')
                      figcaption&.text&.strip
                    end

          # Extract ID if present
          id = audio_elem['id'] || element['id']

          # Extract audio attributes
          metadata = extract_audio_metadata(audio_elem)
          metadata[:src] = src

          Coradoc::CoreModel::Block.new(
            element_type: 'audio',
            content: src,
            title: caption,
            id: id,
            metadata: metadata
          )
        end

        def self.build_attributes(audio)
          attrs = []

          # Extract options from metadata
          options = audio.metadata&.dig(:options) || []

          # Add controls by default (unless nocontrols option is set)
          has_controls = !options.include?('nocontrols')
          attrs << ' controls' if has_controls

          # Add autoplay if specified in options
          attrs << ' autoplay' if options.include?('autoplay')

          # Add loop if specified in options
          attrs << ' loop' if options.include?('loop')

          # Add muted if specified in options
          attrs << ' muted' if options.include?('muted')

          # Add ID if present
          attrs << %( id="#{escape_attribute(audio.id)}") if audio.id

          attrs.join
        end

        def self.build_type_attr(src)
          # Determine audio MIME type from extension
          ext = File.extname(src).downcase
          type = case ext
                 when '.mp3'
                   'audio/mpeg'
                 when '.ogg', '.oga'
                   'audio/ogg'
                 when '.wav'
                   'audio/wav'
                 when '.m4a'
                   'audio/mp4'
                 when '.aac'
                   'audio/aac'
                 when '.flac'
                   'audio/flac'
                 end

          type ? %( type="#{type}") : ''
        end

        def self.build_figure_attrs(audio)
          attrs = []

          # Add ID to figure if present
          attrs << %( id="#{escape_attribute(audio.id)}-figure") if audio.id

          attrs.join
        end

        def self.extract_audio_src(element)
          # Try to get src from <source> tag first
          source = element.at_css('source')
          return source['src'] if source && source['src']

          # Fall back to src attribute on <audio>
          element['src']
        end

        def self.extract_audio_metadata(element)
          metadata = {}
          options = []

          # Extract boolean attributes
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

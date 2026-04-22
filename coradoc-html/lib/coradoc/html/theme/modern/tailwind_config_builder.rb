# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        # Build Tailwind CSS configuration
        module TailwindConfigBuilder
          class << self
            # Build Tailwind configuration
            #
            # @param config [Hash] Theme configuration
            # @return [String] Tailwind configuration script
            def build(config)
              primary = config[:primary_color] || '#6366f1'
              accent = config[:accent_color] || '#8b5cf6'

              # Parse hex colors to RGB for opacity variants
              primary_rgb = hex_to_rgb(primary)
              accent_rgb = hex_to_rgb(accent)

              <<~JS
                tailwind.config = {
                  darkMode: 'class',
                  theme: {
                    extend: {
                      colors: {
                        primary: {
                          DEFAULT: '#{primary}',
                          rgb: '#{primary_rgb}',
                          50: '#{adjust_color(primary, 40)}',
                          100: '#{adjust_color(primary, 30)}',
                          200: '#{adjust_color(primary, 20)}',
                          300: '#{adjust_color(primary, 10)}',
                          400: '#{adjust_color(primary, 5)}',
                          500: '#{primary}',
                          600: '#{adjust_color(primary, -5)}',
                          700: '#{adjust_color(primary, -10)}',
                          800: '#{adjust_color(primary, -20)}',
                          900: '#{adjust_color(primary, -30)}',
                        },
                        accent: {
                          DEFAULT: '#{accent}',
                          rgb: '#{accent_rgb}',
                          50: '#{adjust_color(accent, 40)}',
                          100: '#{adjust_color(accent, 30)}',
                          200: '#{adjust_color(accent, 20)}',
                          300: '#{adjust_color(accent, 10)}',
                          400: '#{adjust_color(accent, 5)}',
                          500: '#{accent}',
                          600: '#{adjust_color(accent, -5)}',
                          700: '#{adjust_color(accent, -10)}',
                          800: '#{adjust_color(accent, -20)}',
                          900: '#{adjust_color(accent, -30)}',
                        },
                      },
                      fontFamily: {
                        sans: [
                          'system-ui',
                          '-apple-system',
                          'BlinkMacSystemFont',
                          'Segoe UI',
                          'Roboto',
                          'sans-serif',
                        ],
                        mono: [
                          'ui-monospace',
                          'SFMono-Regular',
                          'Menlo',
                          'Monaco',
                          'Consolas',
                          'monospace',
                        ],
                      },
                      maxWidth: {
                        'content': '#{config[:content_width] || '65ch'}',
                        'sidebar': '#{config[:sidebar_width] || '280px'}',
                      },
                      animation: {
                        'fade-in': 'fadeIn #{config[:animation_duration] || '300ms'} ease-out',
                        'slide-up': 'slideUp #{config[:animation_duration] || '300ms'} ease-out',
                        'slide-down': 'slideDown #{config[:animation_duration] || '300ms'} ease-out',
                        'scale-in': 'scaleIn #{config[:animation_duration] || '300ms'} ease-out',
                      },
                      keyframes: {
                        fadeIn: {
                          '0%': { opacity: '0' },
                          '100%': { opacity: '1' },
                        },
                        slideUp: {
                          '0%': { transform: 'translateY(10px)', opacity: '0' },
                          '100%': { transform: 'translateY(0)', opacity: '1' },
                        },
                        slideDown: {
                          '0%': { transform: 'translateY(-10px)', opacity: '0' },
                          '100%': { transform: 'translateY(0)', opacity: '1' },
                        },
                        scaleIn: {
                          '0%': { transform: 'scale(0.95)', opacity: '0' },
                          '100%': { transform: 'scale(1)', opacity: '1' },
                        },
                      },
                    },
                  },
                }
              JS
            end

            private

            # Convert hex color to RGB format
            #
            # @param hex [String] Hex color code
            # @return [String] RGB format
            def hex_to_rgb(hex)
              hex = hex.delete('#')
              case hex.length
              when 3
                r, g, b = hex.chars.map { |c| "#{c}#{c}".hex }
              when 6
                r = hex[0..1].hex
                g = hex[2..3].hex
                b = hex[4..5].hex
              else
                return '99, 102, 241' # Default to indigo-500
              end
              "#{r}, #{g}, #{b}"
            end

            # Adjust color lightness
            #
            # @param hex [String] Hex color code
            # @param amount [Integer] Amount to adjust (-100 to 100)
            # @return [String] Adjusted hex color
            def adjust_color(hex, amount)
              # Simple color adjustment
              hex = hex.delete('#')
              r = hex[0..1].hex
              g = hex[2..3].hex
              b = hex[4..5].hex

              amount = amount.to_i
              if amount.positive?
                # Lighten
                factor = 1 + (amount / 100.0)
                r = [(r * factor).round, 255].min
                g = [(g * factor).round, 255].min
                b = [(b * factor).round, 255].min
              elsif amount.negative?
                # Darken
                factor = 1 - (amount.abs / 100.0)
                r = [(r * factor).round, 0].max
                g = [(g * factor).round, 0].max
                b = [(b * factor).round, 0].max
              end

              format('%02x%02x%02x', r, g, b)
            end
          end
        end
      end
    end
  end
end

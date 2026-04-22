# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        # Generate custom CSS for glass morphism and special effects
        module CSSGenerator
          class << self
            # Generate custom CSS
            #
            # @param config [Hash] Theme configuration
            # @return [String] CSS content
            def generate(config)
              <<~CSS
                /* Glass Morphism Effects */
                .glass {
                  background: rgba(255, 255, 255, 0.1);
                  backdrop-filter: blur(10px);
                  -webkit-backdrop-filter: blur(10px);
                  border: 1px solid rgba(255, 255, 255, 0.2);
                }

                .glass-dark {
                  background: rgba(0, 0, 0, 0.2);
                  backdrop-filter: blur(10px);
                  -webkit-backdrop-filter: blur(10px);
                  border: 1px solid rgba(255, 255, 255, 0.1);
                }

                /* Custom scrollbar */
                ::-webkit-scrollbar {
                  width: 8px;
                  height: 8px;
                }

                ::-webkit-scrollbar-track {
                  background: rgba(0, 0, 0, 0.05);
                  border-radius: 4px;
                }

                ::-webkit-scrollbar-thumb {
                  background: rgba(99, 102, 241, 0.5);
                  border-radius: 4px;
                  transition: background 0.3s;
                }

                ::-webkit-scrollbar-thumb:hover {
                  background: rgba(99, 102, 241, 0.7);
                }

                .dark ::-webkit-scrollbar-track {
                  background: rgba(255, 255, 255, 0.05);
                }

                .dark ::-webkit-scrollbar-thumb {
                  background: rgba(139, 92, 246, 0.5);
                }

                .dark ::-webkit-scrollbar-thumb:hover {
                  background: rgba(139, 92, 246, 0.7);
                }

                /* Reading progress bar */
                #reading-progress {
                  position: fixed;
                  top: 0;
                  left: 0;
                  height: 3px;
                  background: linear-gradient(90deg, #{config[:primary_color]}, #{config[:accent_color]});
                  transition: width 0.1s ease-out;
                  z-index: 9999;
                }

                /* Back to top button */
                #back-to-top {
                  position: fixed;
                  bottom: 2rem;
                  right: 2rem;
                  width: 3rem;
                  height: 3rem;
                  border-radius: 50%;
                  background: #{config[:primary_color]};
                  color: white;
                  border: none;
                  cursor: pointer;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                  transition: all 0.3s ease;
                  z-index: 1000;
                }

                #back-to-top:hover {
                  transform: translateY(-2px);
                  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
                }

                #back-to-top.hidden {
                  opacity: 0;
                  pointer-events: none;
                  transform: translateY(10px);
                }

                /* Theme toggle button */
                #theme-toggle {
                  position: fixed;
                  top: 1rem;
                  right: 1rem;
                  padding: 0.5rem;
                  border-radius: 0.5rem;
                  background: rgba(255, 255, 255, 0.9);
                  border: 1px solid rgba(0, 0, 0, 0.1);
                  cursor: pointer;
                  transition: all 0.3s ease;
                  z-index: 1000;
                }

                .dark #theme-toggle {
                  background: rgba(0, 0, 0, 0.5);
                  border-color: rgba(255, 255, 255, 0.1);
                }

                #theme-toggle:hover {
                  transform: scale(1.05);
                }

                /* Table of contents */
                .toc-sidebar {
                  position: fixed;
                  top: 0;
                  left: 0;
                  height: 100vh;
                  width: #{config[:sidebar_width] || '280px'};
                  padding: 2rem 1rem;
                  overflow-y: auto;
                  background: rgba(255, 255, 255, 0.95);
                  backdrop-filter: blur(10px);
                  border-right: 1px solid rgba(0, 0, 0, 0.1);
                  transition: transform 0.3s ease;
                  z-index: 100;
                }

                .dark .toc-sidebar {
                  background: rgba(0, 0, 0, 0.5);
                  border-right-color: rgba(255, 255, 255, 0.1);
                }

                .toc-sidebar.collapsed {
                  transform: translateX(-100%);
                }

                .toc-item {
                  padding: 0.5rem;
                  border-radius: 0.375rem;
                  cursor: pointer;
                  transition: all 0.2s ease;
                }

                .toc-item:hover {
                  background: rgba(99, 102, 241, 0.1);
                }

                .toc-item.active {
                  background: rgba(99, 102, 241, 0.2);
                  color: #{config[:primary_color]};
                  font-weight: 500;
                }

                /* Code blocks */
                pre {
                  position: relative;
                  border-radius: 0.5rem;
                  overflow: hidden;
                }

                .copy-code-button {
                  position: absolute;
                  top: 0.5rem;
                  right: 0.5rem;
                  padding: 0.25rem 0.5rem;
                  font-size: 0.75rem;
                  border-radius: 0.25rem;
                  background: rgba(255, 255, 255, 0.9);
                  border: 1px solid rgba(0, 0, 0, 0.1);
                  cursor: pointer;
                  opacity: 0;
                  transition: opacity 0.2s ease;
                }

                pre:hover .copy-code-button {
                  opacity: 1;
                }

                .copy-code-button.copied {
                  background: rgba(34, 197, 94, 0.9);
                  color: white;
                }

                /* Admonition styles */
                .admonition {
                  border-radius: 0.5rem;
                  padding: 1rem;
                  margin: 1rem 0;
                  border-left: 4px solid;
                }

                .admonition-note {
                  background: rgba(59, 130, 246, 0.1);
                  border-color: rgb(59, 130, 246);
                }

                .admonition-tip {
                  background: rgba(34, 197, 94, 0.1);
                  border-color: rgb(34, 197, 94);
                }

                .admonition-warning {
                  background: rgba(251, 191, 36, 0.1);
                  border-color: rgb(251, 191, 36);
                }

                .admonition-caution {
                  background: rgba(239, 68, 68, 0.1);
                  border-color: rgb(239, 68, 68);
                }

                .admonition-important {
                  background: rgba(139, 92, 246, 0.1);
                  border-color: rgb(139, 92, 246);
                }

                /* Print styles */
                @media print {
                  #reading-progress,
                  #back-to-top,
                  #theme-toggle,
                  .toc-sidebar {
                    display: none !important;
                  }

                  .content-wrapper {
                    max-width: 100% !important;
                  }
                }

                #{config[:enable_animations] ? animation_css : ''}
              CSS
            end

            private

            # Animation CSS
            #
            # @return [String] Animation CSS
            def animation_css
              <<~CSS
                /* Animations */
                @media (prefers-reduced-motion: no-preference) {
                  .animate-fade-in {
                    animation: fadeIn 0.3s ease-out;
                  }

                  .animate-slide-up {
                    animation: slideUp 0.3s ease-out;
                  }

                  .animate-scale-in {
                    animation: scaleIn 0.3s ease-out;
                  }
                }

                @keyframes fadeIn {
                  from {
                    opacity: 0;
                  }
                  to {
                    opacity: 1;
                  }
                }

                @keyframes slideUp {
                  from {
                    opacity: 0;
                    transform: translateY(10px);
                  }
                  to {
                    opacity: 1;
                    transform: translateY(0);
                  }
                }

                @keyframes scaleIn {
                  from {
                    opacity: 0;
                    transform: scale(0.95);
                  }
                  to {
                    opacity: 1;
                    transform: scale(1);
                  }
                }
              CSS
            end
          end
        end
      end
    end
  end
end

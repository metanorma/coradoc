# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        # UI component templates for interactive elements
        module UIComponents
          class << self
            # Generate UI components HTML
            #
            # @param config [Hash] Theme configuration
            # @return [String] UI components HTML
            def generate_html(config)
              <<~HTML
                <!-- Reading Progress Bar -->
                #{reading_progress_html(config)}

                <!-- Theme Toggle Button -->
                #{theme_toggle_html(config)}

                <!-- Back to Top Button -->
                #{back_to_top_html(config)}
              HTML
            end

            # Reading progress bar HTML
            #
            # @param config [Hash] Theme configuration
            # @return [String] Reading progress bar HTML
            def reading_progress_html(config)
              return '' unless config[:reading_progress]

              <<~HTML
                <div id="reading-progress" :style="{ width: scrollProgress + '%' }"></div>
              HTML
            end

            # Theme toggle button HTML
            #
            # @param config [Hash] Theme configuration
            # @return [String] Theme toggle button HTML
            def theme_toggle_html(config)
              return '' unless config[:theme_toggle]

              <<~HTML
                <button
                  id="theme-toggle"
                  @click="toggleTheme"
                  :title="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
                  aria-label="Toggle dark mode"
                  class="fixed top-4 right-4 p-2 rounded-full bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border border-gray-200 dark:border-gray-700 shadow-lg hover:shadow-xl transition-all hover:scale-110 z-50"
                >
                  <svg v-if="!isDark" class="w-5 h-5 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h1a1 1 0 100 2h-1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" />
                  </svg>
                  <svg v-else class="w-5 h-5 text-indigo-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                </button>
              HTML
            end

            # Back to top button HTML
            #
            # @param config [Hash] Theme configuration
            # @return [String] Back to top button HTML
            def back_to_top_html(config)
              return '' unless config[:back_to_top]

              <<~HTML
                <button
                  id="back-to-top"
                  v-show="showBackToTop"
                  @click="scrollToTop"
                  title="Back to top"
                  aria-label="Back to top"
                  class="fixed bottom-6 right-6 p-3 rounded-full bg-gradient-to-r from-primary-600 to-primary-500 text-white shadow-lg hover:shadow-xl transition-all hover:scale-110 z-50"
                  :class="{ 'opacity-0 pointer-events-none translate-y-2': !showBackToTop }"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
                  </svg>
                </button>
              HTML
            end

            # Enhanced document template with UI components
            #
            # @return [String] Enhanced document template
            def enhanced_document_template(_config)
              <<~VUE
                <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 transition-colors duration-300">
                  <!-- Reading Progress Bar -->
                  <div v-if="config.reading_progress" class="reading-progress-bar" :style="{ width: scrollProgress + '%' }"></div>

                  <!-- Theme Toggle Button -->
                  <button
                    v-if="config.theme_toggle"
                    @click="toggleTheme"
                    class="theme-toggle-btn"
                    :title="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
                  >
                    <svg v-if="!isDark" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h1a1 1 0 100 2h-1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" />
                    </svg>
                    <svg v-else class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                    </svg>
                  </button>

                  <!-- Back to Top Button -->
                  <button
                    v-if="config.back_to_top"
                    v-show="showBackToTop"
                    @click="scrollToTop"
                    class="back-to-top-btn"
                    title="Back to top"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
                    </svg>
                  </button>

                  <!-- Main Document Container -->
                  <div class="document-container mx-auto px-4 py-8 max-w-7xl">
                    <div class="flex gap-8">
                      <!-- TOC Sidebar -->
                      <aside v-if="config.toc_sticky && showToc" class="toc-sidebar" :class="{ 'collapsed': tocCollapsed }">
                        <nav class="toc-nav sticky top-4">
                          <h3 class="toc-title text-lg font-semibold mb-4 text-gray-900 dark:text-white">Contents</h3>
                          <ul class="toc-list space-y-1">
                            <li
                              v-for="item in tocItems"
                              :key="item.id"
                              @click="scrollToSection(item.id)"
                              class="toc-item p-2 rounded-lg cursor-pointer transition-all"
                              :class="{ 'active': activeSection === item.id }"
                              :style="{ paddingLeft: (item.level * 0.75 + 1) + 'rem' }"
                            >
                              {{ item.title }}
                            </li>
                          </ul>
                        </nav>
                      </aside>

                      <!-- Main Content -->
                      <main class="flex-1 min-w-0">
                        <article class="prose prose-lg dark:prose-invert max-w-none
                                       prose-headings:text-gray-900 dark:prose-headings:text-white
                                       prose-p:text-gray-700 dark:prose-p:text-gray-300
                                       prose-a:text-primary-600 dark:prose-a:text-primary-400
                                       prose-strong:text-gray-900 dark:prose-strong:text-white
                                       prose-code:text-pink-600 dark:prose-code:text-pink-400
                                       prose-pre:bg-gray-100 dark:prose-pre:bg-gray-800">
                          <template v-for="(section, index) in document.sections" :key="section.id || index">
                            <component :is="'section-' + section.type" :data="section" v-if="section.type === 'section'" />
                            <component :is="'element-' + section.type" :data="section" v-else />
                          </template>
                        </article>
                      </main>
                    </div>
                  </div>
                </div>
              VUE
            end

            # Generate complete CSS with enhanced styles
            #
            # @param config [Hash] Theme configuration
            # @return [String] Enhanced CSS
            def enhanced_css(config)
              base_css = CSSGenerator.generate(config)

              base_css + <<~CSS

                /* Reading Progress Bar */
                .reading-progress-bar {
                  position: fixed;
                  top: 0;
                  left: 0;
                  height: 3px;
                  background: linear-gradient(90deg, #{config[:primary_color]}, #{config[:accent_color]});
                  transition: width 0.1s ease-out;
                  z-index: 9999;
                }

                /* Theme Toggle Button */
                .theme-toggle-btn {
                  position: fixed;
                  top: 1.5rem;
                  right: 1.5rem;
                  width: 2.75rem;
                  height: 2.75rem;
                  border-radius: 9999px;
                  background: rgba(255, 255, 255, 0.9);
                  backdrop-filter: blur(10px);
                  border: 1px solid rgba(0, 0, 0, 0.1);
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  cursor: pointer;
                  transition: all 0.3s ease;
                  z-index: 1000;
                }

                .theme-toggle-btn:hover {
                  transform: scale(1.1);
                  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
                }

                .dark .theme-toggle-btn {
                  background: rgba(0, 0, 0, 0.5);
                  border-color: rgba(255, 255, 255, 0.1);
                }

                /* Back to Top Button */
                .back-to-top-btn {
                  position: fixed;
                  bottom: 1.5rem;
                  right: 1.5rem;
                  width: 3rem;
                  height: 3rem;
                  border-radius: 9999px;
                  background: linear-gradient(135deg, #{config[:primary_color]}, #{config[:accent_color]});
                  color: white;
                  border: none;
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  cursor: pointer;
                  transition: all 0.3s ease;
                  opacity: 1;
                  transform: translateY(0);
                  z-index: 1000;
                }

                .back-to-top-btn:hover {
                  transform: translateY(-2px);
                  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
                }

                .back-to-top-btn.opacity-0 {
                  opacity: 0;
                  pointer-events: none;
                  transform: translateY(10px);
                }

                /* TOC Sidebar */
                .toc-sidebar {
                  position: sticky;
                  top: 2rem;
                  width: #{config[:sidebar_width] || '280px'};
                  max-height: calc(100vh - 4rem);
                  overflow-y: auto;
                  padding: 1.5rem;
                  background: rgba(255, 255, 255, 0.8);
                  backdrop-filter: blur(10px);
                  border: 1px solid rgba(0, 0, 0, 0.1);
                  border-radius: 0.75rem;
                  transition: all 0.3s ease;
                  z-index: 100;
                }

                .dark .toc-sidebar {
                  background: rgba(0, 0, 0, 0.5);
                  border-color: rgba(255, 255, 255, 0.1);
                }

                .toc-sidebar.collapsed {
                  transform: translateX(-120%);
                  opacity: 0;
                }

                .toc-item {
                  display: block;
                  color: #6b7280;
                  transition: all 0.2s ease;
                }

                .dark .toc-item {
                  color: #9ca3af;
                }

                .toc-item:hover {
                  background: rgba(99, 102, 241, 0.1);
                  color: #{config[:primary_color]};
                }

                .toc-item.active {
                  background: linear-gradient(135deg, rgba(99, 102, 241, 0.15), rgba(139, 92, 246, 0.15));
                  color: #{config[:primary_color]};
                  font-weight: 600;
                }

                /* Document Container */
                .document-container {
                  background: transparent;
                }

                /* Smooth animations */
                @media (prefers-reduced-motion: no-preference) {
                  .toc-item {
                    animation: slideIn 0.3s ease-out;
                  }

                  @keyframes slideIn {
                    from {
                      opacity: 0;
                      transform: translateX(-10px);
                    }
                    to {
                      opacity: 1;
                      transform: translateX(0);
                    }
                  }
                }

                /* Responsive */
                @media (max-width: 1024px) {
                  .toc-sidebar {
                    position: fixed;
                    left: 0;
                    top: 0;
                    height: 100vh;
                    max-height: 100vh;
                    z-index: 200;
                    transform: translateX(-100%);
                  }

                  .toc-sidebar:not(.collapsed) {
                    transform: translateX(0);
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

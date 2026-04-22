# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        # Generate Vue.js application code
        module JavascriptGenerator
          class << self
            # Generate Vue application
            #
            # @param document_data [Hash] Serialized document data
            # @param config [Hash] Theme configuration
            # @return [String] Vue application JavaScript
            def generate(document_data, config)
              # Get Vue templates
              templates = load_templates

              # Get enhanced document template
              require_relative 'components/ui_components'
              document_template = UIComponents.enhanced_document_template(config)

              <<~JS
                const { createApp, ref, computed, onMounted, onUnmounted } = Vue;

                // Define Vue components
                const components = {
                  'element-paragraph': {
                    props: ['data'],
                    template: `#{templates[:paragraph]}`
                  },
                  'element-admonition': {
                    props: ['data'],
                    setup(props) {
                      const admonitionIcon = (style) => {
                        const styles = { note: '📝', tip: '💡', warning: '⚠️', caution: '🔥', important: '❗' };
                        return styles[style?.toLowerCase()] || 'ℹ️';
                      };
                      const admonitionTitle = (style) => style?.charAt(0).toUpperCase() + style?.slice(1) || 'Note';
                      return { admonitionIcon, admonitionTitle };
                    },
                    template: `#{templates[:admonition]}`
                  },
                  'element-list': {
                    props: ['data'],
                    template: `#{templates[:list]}`
                  },
                  'element-block': {
                    props: ['data'],
                    setup(props) {
                      const blockContent = (data) => {
                        if (!data.content || data.content.length === 0) return '';
                        return data.content.map(item => item.content || item.text || '').join('');
                      };
                      const cellContent = (cell) => {
                        if (!cell.content || cell.content.length === 0) return '';
                        return cell.content.map(item => item.content || item.text || '').join('');
                      };
                      return { blockContent, cellContent };
                    },
                    template: `#{templates[:block]}`
                  },
                  'element-table': {
                    props: ['data'],
                    setup(props) {
                      const cellContent = (cell) => {
                        if (!cell.content || cell.content.length === 0) return '';
                        return cell.content.map(item => item.content || item.text || '').join('');
                      };
                      return { cellContent };
                    },
                    template: `#{templates[:table]}`
                  },
                  'element-image': {
                    props: ['data'],
                    template: `#{templates[:image]}`
                  },
                  'element-link': {
                    props: ['data'],
                    template: `#{templates[:link]}`
                  },
                  'element-xref': {
                    props: ['data'],
                    template: `#{templates[:xref]}`
                  },
                  'element-text': {
                    props: ['data'],
                    template: '<span>{{ data.content || data }}</span>'
                  },
                  'inline-bold': {
                    props: ['data'],
                    template: '<strong><template v-for="(item, i) in data.content" :key="i">{{ item.content || item }}</template></strong>'
                  },
                  'inline-italic': {
                    props: ['data'],
                    template: '<em><template v-for="(item, i) in data.content" :key="i">{{ item.content || item }}</template></em>'
                  },
                  'inline-monospace': {
                    props: ['data'],
                    template: '<code class="bg-gray-100 dark:bg-gray-800 px-1 py-0.5 rounded text-sm"><template v-for="(item, i) in data.content" :key="i">{{ item.content || item }}</template></code>'
                  },
                  'inline-text': {
                    props: ['data'],
                    setup(props) {
                      const renderContent = (content) => {
                        if (!content) return '';
                        if (typeof content === 'string') return content;
                        if (Array.isArray(content)) {
                          return content.map(item => item.content || item.text || item).join('');
                        }
                        return content;
                      };
                      return { renderContent };
                    },
                    template: '<span>{{ renderContent(data.content) || data.text || data }}</span>'
                  },
                  'section-section': {
                    props: ['data'],
                    template: `#{templates[:section]}`
                  },
                };

                const app = createApp({
                  components,
                  template: `#{document_template}`,
                  setup() {
                    // Document data (use docData to avoid shadowing global document)
                    const docData = #{JSON.generate(document_data)};
                    const config = #{JSON.generate(config)};

                    // UI state
                    const isDark = ref(false);
                    const showToc = ref(#{config[:toc_sticky]});
                    const tocCollapsed = ref(false);
                    const activeSection = ref('');
                    const showBackToTop = ref(false);
                    const scrollProgress = ref(0);

                    // Initialize theme from localStorage or system preference
                    onMounted(() => {
                      // Theme detection
                      const storedTheme = localStorage.getItem('theme');
                      if (storedTheme) {
                        isDark.value = storedTheme === 'dark';
                      } else {
                        isDark.value = window.matchMedia('(prefers-color-scheme: dark)').matches;
                      }
                      applyTheme();

                      // Scroll listeners
                      window.addEventListener('scroll', handleScroll);
                      window.addEventListener('resize', handleResize);

                      // Initialize intersection observer for active section
                      initObserver();
                    });

                    onUnmounted(() => {
                      window.removeEventListener('scroll', handleScroll);
                      window.removeEventListener('resize', handleResize);
                    });

                    // Theme toggle
                    function toggleTheme() {
                      isDark.value = !isDark.value;
                      applyTheme();
                      localStorage.setItem('theme', isDark.value ? 'dark' : 'light');
                    }

                    function applyTheme() {
                      if (isDark.value) {
                        document.documentElement.classList.add('dark');
                      } else {
                        document.documentElement.classList.remove('dark');
                      }
                    }

                    // Scroll handlers
                    function handleScroll() {
                      // Update scroll progress
                      const scrollTop = window.scrollY;
                      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
                      scrollProgress.value = (scrollTop / docHeight) * 100;

                      // Show/hide back to top button
                      showBackToTop.value = scrollTop > 300;
                    }

                    function handleResize() {
                      // Auto-collapse TOC on small screens
                      if (window.innerWidth < 1024) {
                        tocCollapsed.value = true;
                      } else {
                        tocCollapsed.value = false;
                      }
                    }

                    function scrollToTop() {
                      window.scrollTo({ top: 0, behavior: 'smooth' });
                    }

                    function scrollToSection(id) {
                      const element = document.getElementById(id);
                      if (element) {
                        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
                      }
                    }

                    // Intersection observer for active section
                    function initObserver() {
                      const observer = new IntersectionObserver(
                        (entries) => {
                          entries.forEach((entry) => {
                            if (entry.isIntersecting) {
                              activeSection.value = entry.target.id;
                            }
                          });
                        },
                        {
                          rootMargin: '-10% 0px -80% 0px',
                          threshold: 0
                        }
                      );

                      // Observe all sections
                      document.querySelectorAll('section[id]').forEach((section) => {
                        observer.observe(section);
                      });
                    }

                    // Copy code to clipboard
                    async function copyCode(code, event) {
                      try {
                        await navigator.clipboard.writeText(code);
                        const button = event.target;
                        button.textContent = 'Copied!';
                        button.classList.add('copied');
                        setTimeout(() => {
                          button.textContent = 'Copy';
                          button.classList.remove('copied');
                        }, 2000);
                      } catch (err) {
                        console.error('Failed to copy code:', err);
                      }
                    }

                    // Flatten sections for TOC rendering
                    function flattenToc(sections, level = 0) {
                      const result = [];
                      for (const section of sections) {
                        result.push({ ...section, level });
                        if (section.children && section.children.length > 0) {
                          result.push(...flattenToc(section.children, level + 1));
                        }
                      }
                      return result;
                    }

                    // Computed properties
                    const tocItems = computed(() => flattenToc(docData.toc || []));

                    return {
                      document: docData,
                      config,
                      isDark,
                      showToc,
                      tocCollapsed,
                      activeSection,
                      showBackToTop,
                      scrollProgress,
                      tocItems,
                      toggleTheme,
                      scrollToTop,
                      scrollToSection,
                      copyCode,
                    };
                  },
                });

                // Register components globally for dynamic component resolution
                // This allows <component :is="..."> to work in nested templates
                Object.keys(components).forEach((name) => {
                  app.component(name, components[name]);
                });

                app.mount('#app');
              JS
            end

            private

            # Load Vue component templates
            #
            # @return [Hash] Hash of templates
            def load_templates
              require_relative 'vue_template_generator'
              {
                paragraph: VueTemplates.template_for('paragraph'),
                admonition: VueTemplates.template_for('admonition'),
                list: VueTemplates.template_for('list'),
                block: VueTemplates.template_for('block'),
                table: VueTemplates.template_for('table'),
                image: VueTemplates.template_for('image'),
                link: VueTemplates.template_for('link'),
                xref: VueTemplates.template_for('xref'),
                section: VueTemplates.template_for('section')
              }
            end
          end
        end
      end
    end
  end
end

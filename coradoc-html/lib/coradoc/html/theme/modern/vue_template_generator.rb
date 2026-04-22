# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      class ModernRenderer
        # Vue component templates for rendering document elements
        module VueTemplates
          class << self
            # Generate Vue component template for a given element type
            #
            # @param type [String] Element type
            # @return [String] Vue component template
            def template_for(type)
              case type
              when 'document' then document_template
              when 'section' then section_template
              when 'paragraph' then paragraph_template
              when 'admonition' then admonition_template
              when 'list' then list_template
              when 'block' then block_template
              when 'table' then table_template
              when 'image' then image_template
              when 'link' then link_template
              when 'xref' then cross_reference_template
              else
                generic_template
              end
            end

            # Document component template
            #
            # @return [String] Document template
            def document_template
              <<~VUE
                <div class="document-wrapper">
                  <header v-if="document.header" class="document-header mb-8">
                    <h1 class="text-4xl font-bold text-gray-900 dark:text-white">
                      {{ document.header.title?.text || document.title || 'Untitled Document' }}
                    </h1>
                    <p v-if="document.header?.author" class="text-gray-600 dark:text-gray-400 mt-2">
                      {{ document.header.author }}
                    </p>
                  </header>

                  <div class="toc-toggle mb-4 flex justify-end">
                    <button
                      @click="tocCollapsed = !tocCollapsed"
                      class="px-4 py-2 rounded-lg bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-all flex items-center gap-2"
                    >
                      <svg class="w-5 h-5" :class="{ 'rotate-180': !tocCollapsed }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                      </svg>
                      <span>{{ tocCollapsed ? 'Show' : 'Hide' }} Contents</span>
                    </button>
                  </div>

                  <div class="flex gap-8">
                    <!-- TOC Sidebar -->
                    <aside v-if="showToc" class="toc-sidebar" :class="{ 'collapsed': tocCollapsed }">
                      <nav class="toc-nav">
                        <h3 class="text-lg font-semibold mb-4 text-gray-900 dark:text-white">Contents</h3>
                        <ul class="space-y-1">
                          <li
                            v-for="item in tocItems"
                            :key="item.id"
                            @click="scrollToSection(item.id)"
                            class="toc-item"
                            :class="{ 'active': activeSection === item.id }"
                            :style="{ paddingLeft: (item.level * 0.75) + 'rem' }"
                          >
                            {{ item.title }}
                          </li>
                        </ul>
                      </nav>
                    </aside>

                    <!-- Main Content -->
                    <main class="flex-1 min-w-0">
                      <article class="prose prose-lg dark:prose-invert max-w-none">
                        <template v-for="(section, index) in document.sections" :key="section.id || index">
                          <component :is="'section-' + section.type" :data="section" v-if="section.type === 'section'" />
                          <component :is="'element-' + section.type" :data="section" v-else />
                        </template>
                      </article>
                    </main>
                  </div>
                </div>
              VUE
            end

            # Section component template
            #
            # @return [String] Section template
            def section_template
              <<~VUE
                <section :id="data.id" class="section scroll-mt-20">
                  <h1 v-if="data.level === 1" class="section-title text-3xl font-bold mb-4">{{ data.title?.text || data.title }}</h1>
                  <h2 v-else-if="data.level === 2" class="section-title text-2xl font-semibold mb-3">{{ data.title?.text || data.title }}</h2>
                  <h3 v-else-if="data.level === 3" class="section-title text-xl font-semibold mb-2">{{ data.title?.text || data.title }}</h3>
                  <h4 v-else-if="data.level === 4" class="section-title text-lg font-semibold mb-2">{{ data.title?.text || data.title }}</h4>
                  <h5 v-else-if="data.level === 5" class="section-title text-base font-semibold mb-1">{{ data.title?.text || data.title }}</h5>
                  <h2 v-else class="section-title text-2xl font-semibold mb-3">{{ data.title?.text || data.title }}</h2>

                  <div class="section-content">
                    <template v-for="(item, index) in data.content" :key="item.id || index">
                      <component :is="'element-' + item.type" :data="item" />
                    </template>

                    <template v-if="data.sections && data.sections.length > 0">
                      <template v-for="(subsection, index) in data.sections" :key="subsection.id || index">
                        <component :is="'section-section'" :data="subsection" />
                      </template>
                    </template>
                  </div>
                </section>
              VUE
            end

            # Paragraph component template
            #
            # @return [String] Paragraph template
            def paragraph_template
              <<~VUE
                <p :id="data.id" class="paragraph leading-relaxed">
                  <template v-for="(item, index) in data.content" :key="item.id || index">
                    <component :is="'inline-' + item.type" v-if="item.type" :data="item" />
                    <span v-else>{{ item.content || item }}</span>
                  </template>
                </p>
              VUE
            end

            # Admonition component template
            #
            # @return [String] Admonition template
            def admonition_template
              <<~VUE
                <div :id="data.id" :class="['admonition', 'admonition-' + data.style.toLowerCase()]">
                  <div class="admonition-title font-semibold mb-2 flex items-center gap-2">
                    <span class="admonition-icon">{{ admonitionIcon(data.style) }}</span>
                    <span>{{ data.title || admonitionTitle(data.style) }}</span>
                  </div>
                  <div class="admonition-content">
                    <template v-for="(item, index) in data.content" :key="item.id || index">
                      <component :is="'element-' + item.type" :data="item" />
                    </template>
                  </div>
                </div>
              VUE
            end

            # List component template
            #
            # @return [String] List template
            def list_template
              <<~VUE
                <div :id="data.id" class="list-wrapper">
                  <ul v-if="data.list_type === 'unordered'" class="list-disc list-inside space-y-1">
                    <li v-for="(item, index) in data.items" :key="item.id || index" class="list-item">
                      <template v-for="(content, idx) in item.content" :key="content.id || idx">
                        <component :is="'element-' + content.type" :data="content" />
                      </template>
                    </li>
                  </ul>

                  <ol v-else-if="data.list_type === 'ordered'" class="list-decimal list-inside space-y-1">
                    <li v-for="(item, index) in data.items" :key="item.id || index" class="list-item">
                      <template v-for="(content, idx) in item.content" :key="content.id || idx">
                        <component :is="'element-' + content.type" :data="content" />
                      </template>
                    </li>
                  </ol>

                  <dl v-else-if="data.list_type === 'definition'" class="space-y-2">
                    <template v-for="(item, index) in data.items" :key="item.id || index">
                      <div class="definition-item">
                        <dt class="font-semibold">{{ item.terms?.join(', ') }}</dt>
                        <dd class="ml-4">
                          <template v-for="(content, idx) in item.content" :key="content.id || idx">
                            <component :is="'element-' + content.type" :data="content" />
                          </template>
                        </dd>
                      </div>
                    </template>
                  </dl>
                </div>
              VUE
            end

            # Block component template (listing, literal, example, quote)
            #
            # @return [String] Block template
            def block_template
              <<~VUE
                <div :id="data.id" :class="['block', 'block-' + data.block_type.toLowerCase()]">
                  <div v-if="data.title" class="block-title font-semibold mb-2">{{ data.title }}</div>

                  <div v-if="data.block_type === 'listing' || data.block_type === 'literal'" class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 overflow-x-auto">
                    <pre class="whitespace-pre-wrap">{{ blockContent(data) }}</pre>
                    <button
                      @click="copyCode(blockContent(data), $event)"
                      class="copy-code-button"
                    >
                      Copy
                    </button>
                  </div>

                  <blockquote v-else-if="data.block_type === 'quote'" class="border-l-4 border-primary-500 pl-4 italic">
                    <template v-for="(item, index) in data.content" :key="item.id || index">
                      <component :is="'element-' + item.type" :data="item" />
                    </template>
                  </blockquote>

                  <div v-else class="block-content">
                    <template v-for="(item, index) in data.content" :key="item.id || index">
                      <component :is="'element-' + item.type" :data="item" />
                    </template>
                  </div>
                </div>
              VUE
            end

            # Table component template
            #
            # @return [String] Table template
            def table_template
              <<~VUE
                <div :id="data.id" class="table-wrapper overflow-x-auto my-4">
                  <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <caption v-if="data.caption" class="caption-bottom text-sm text-gray-600 dark:text-gray-400 py-2">
                      {{ data.caption }}
                    </caption>

                    <thead v-if="data.header && data.header.length > 0" class="bg-gray-50 dark:bg-gray-800">
                      <tr>
                        <th
                          v-for="(cell, index) in data.header[0].cells"
                          :key="cell.id || index"
                          class="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                          :colspan="cell.colspan"
                          :rowspan="cell.rowspan"
                        >
                          {{ cellContent(cell) }}
                        </th>
                      </tr>
                    </thead>

                    <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                      <tr v-for="(row, rowIndex) in data.body" :key="row.id || rowIndex" class="hover:bg-gray-50 dark:hover:bg-gray-800">
                        <td
                          v-for="(cell, cellIndex) in row.cells"
                          :key="cell.id || cellIndex"
                          class="px-4 py-2 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100"
                          :colspan="cell.colspan"
                          :rowspan="cell.rowspan"
                        >
                          <template v-for="(item, index) in cell.content" :key="item.id || index">
                            <component :is="'element-' + item.type" :data="item" />
                          </template>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              VUE
            end

            # Image component template
            #
            # @return [String] Image template
            def image_template
              <<~VUE
                <figure :id="data.id" :class="data.inline ? 'inline-image' : 'block-image'" class="my-4">
                  <img
                    :src="data.src"
                    :alt="data.alt || ''"
                    :title="data.title"
                    :width="data.width"
                    :height="data.height"
                    :class="data.inline ? 'inline max-h-6 align-middle' : 'w-full rounded-lg shadow-lg'"
                  />
                  <figcaption v-if="data.title" class="text-center text-sm text-gray-600 dark:text-gray-400 mt-2">
                    {{ data.title }}
                  </figcaption>
                </figure>
              VUE
            end

            # Link component template
            #
            # @return [String] Link template
            def link_template
              <<~VUE
                <a
                  :href="data.href"
                  :target="data.target || '_blank'"
                  :rel="data.target === '_blank' ? 'noopener noreferrer' : null"
                  class="text-primary-600 dark:text-primary-400 hover:text-primary-800 dark:hover:text-primary-300 underline"
                >
                  <template v-for="(item, index) in data.content" :key="item.id || index">
                    <component :is="'inline-' + item.type" v-if="item.type" :data="item" />
                    <span v-else>{{ item.content || item }}</span>
                  </template>
                </a>
              VUE
            end

            # Cross reference component template
            #
            # @return [String] Cross reference template
            def cross_reference_template
              <<~VUE
                <a
                  :href="'#' + data.target"
                  @click.prevent="scrollToSection(data.target)"
                  class="text-primary-600 dark:text-primary-400 hover:text-primary-800 dark:hover:text-primary-300 underline cursor-pointer"
                >
                  <template v-for="(item, index) in data.content" :key="item.id || index">
                    <component :is="'inline-' + item.type" v-if="item.type" :data="item" />
                    <span v-else>{{ item.content || item }}</span>
                  </template>
                </a>
              VUE
            end

            # Generic component template (fallback)
            #
            # @return [String] Generic template
            def generic_template
              <<~VUE
                <div :id="data.id" :class="['element', 'element-' + data.type]">
                  <template v-if="data.content">
                    <template v-for="(item, index) in data.content" :key="item.id || index">
                      <component :is="'element-' + item.type" :data="item" v-if="item.type" />
                      <span v-else>{{ item.content || item }}</span>
                    </template>
                  </template>
                  <span v-else>{{ data.content || data }}</span>
                </div>
              VUE
            end

            private

            # Get admonition icon
            #
            # @param style [String] Admonition style
            # @return [String] Icon emoji
            def admonition_icon(style)
              case style&.downcase
              when 'note' then '📝'
              when 'tip' then '💡'
              when 'warning' then '⚠️'
              when 'caution' then '🔥'
              when 'important' then '❗'
              else
                'ℹ️'
              end
            end

            # Get admonition title
            #
            # @param style [String] Admonition style
            # @return [String] Title text
            def admonition_title(style)
              style&.capitalize || 'Note'
            end
          end
        end
      end
    end
  end
end

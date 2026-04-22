#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete demonstration of the Liquid Template Override System
# Shows: parsing AsciiDoc -> CoreModel -> HTML with default and custom templates

require 'bundler/setup'
require 'fileutils'
require 'tmpdir'
require 'liquid'
require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/html'

puts '=' * 70
puts 'LIQUID TEMPLATE OVERRIDE DEMONSTRATION'
puts '=' * 70
puts ''

# ==============================================================================
# STEP 1: Create sample bibliography data (simulating parsed AsciiDoc)
# ==============================================================================

puts 'STEP 1: Creating sample bibliography data...'
puts ''

# Sample bibliography entries (like from rice-2023 document)
entries = [
  Coradoc::CoreModel::BibliographyEntry.new(
    anchor_name: 'ISO712',
    document_id: 'ISO 712',
    ref_text: 'Cereals and cereal products. Determination of moisture content. Reference method.'
  ),
  Coradoc::CoreModel::BibliographyEntry.new(
    anchor_name: 'ISO6646',
    document_id: 'ISO 6646',
    ref_text: 'Rice. Determination of the potential amylose content. Reference method.'
  ),
  Coradoc::CoreModel::BibliographyEntry.new(
    anchor_name: 'ISO7301',
    document_id: 'ISO 7301:2011',
    ref_text: 'Rice. Specification.'
  ),
  Coradoc::CoreModel::BibliographyEntry.new(
    anchor_name: 'ISO11747',
    document_id: 'ISO 11747:2012',
    ref_text: 'Rice. Determination of the translucency of milled rice.'
  )
]

bibliography = Coradoc::CoreModel::Bibliography.new(
  id: 'norm-refs',
  title: 'Normative References',
  level: 1,
  entries: entries
)

puts "Created bibliography with #{entries.size} entries"
puts ''

# ==============================================================================
# STEP 2: Render with DEFAULT templates
# ==============================================================================

puts 'STEP 2: Rendering with DEFAULT templates...'
puts '-' * 70

default_renderer = Coradoc::Html::Renderer.new
default_html = default_renderer.render(bibliography)

puts default_html
puts ''

# ==============================================================================
# STEP 3: Create CUSTOM template directory
# ==============================================================================

puts 'STEP 3: Creating custom template directory...'
puts '-' * 70

tmpdir = Dir.mktmpdir('coradoc_custom_templates')
core_model_dir = File.join(tmpdir, 'core_model')
FileUtils.mkdir_p(core_model_dir)

puts "Custom template directory: #{tmpdir}"
puts ''

# ==============================================================================
# CUSTOM TEMPLATE 1: Bibliography with "plain" simple format
# ==============================================================================

custom_bibliography = <<~LIQUID
  {%- comment -%}
    PLAIN BIBLIOGRAPHY TEMPLATE
    Simple, clean format without fancy spans
  {%- endcomment -%}
  <section id="{{ id }}" class="bibliography plain-bib">
    <h{{ level | default: 2 }}>{{ title }}</h{{ level | default: 2 }}>
    <dl class="references">
      {% for entry in entries %}
        <dt>{{ entry.anchor_name }}</dt>
        <dd>{{ entry | render_element }}</dd>
      {% endfor %}
    </dl>
  </section>
LIQUID

File.write(File.join(core_model_dir, 'bibliography.liquid'), custom_bibliography)

# ==============================================================================
# CUSTOM TEMPLATE 2: Bibliography Entry with "calling super" enhanced format
# ==============================================================================

custom_entry = <<~LIQUID
  {%- comment -%}
    ENHANCED BIBLIOGRAPHY ENTRY TEMPLATE
    Shows "calling super" - you can call parent methods/filters
  {%- endcomment -%}

  {%- assign doc_id = document_id | default: "" -%}
  {%- assign ref = ref_text | default: "" -%}

  <div class="bib-entry" data-anchor="{{ anchor_name }}">
    <strong class="doc-id">{{ doc_id }}</strong>
    {%- if ref != "" %}
    <em class="ref-text">{{ ref }}</em>
    {%- endif %}
  </div>
LIQUID

File.write(File.join(core_model_dir, 'bibliography_entry.liquid'), custom_entry)

puts 'Created custom templates:'
puts '  - bibliography.liquid (plain format with <dl>/<dt>/<dd>)'
puts '  - bibliography_entry.liquid (enhanced format with data-anchor)'
puts ''

# ==============================================================================
# STEP 4: Render with CUSTOM templates
# ==============================================================================

puts 'STEP 4: Rendering with CUSTOM templates...'
puts '-' * 70

custom_renderer = Coradoc::Html::Renderer.new(template_dirs: [tmpdir])
custom_html = custom_renderer.render(bibliography)

puts custom_html
puts ''

# ==============================================================================
# STEP 5: Comparison Summary
# ==============================================================================

puts 'STEP 5: COMPARISON SUMMARY'
puts '-' * 70

puts ''
puts 'DEFAULT template features:'
puts "  - <section> with class='bibliography'"
puts "  - <div class='bibliography-entries'> wrapper"
puts "  - ISO spans: <span class='stdpublisher'>ISO</span>"
puts "  - <i><span class='stddocTitle'> for ref text"
puts ''
puts 'CUSTOM template features:'
puts "  - <section> with class='bibliography plain-bib'"
puts "  - <dl class='references'> with <dt>/<dd> structure"
puts "  - Entry uses: <strong class='doc-id'> (no ISO spans)"
puts "  - <em class='ref-text'> for ref text"
puts '  - data-anchor attribute for linking'
puts ''
puts 'KEY POINT: render_element filter finds the right template!'
puts '  - bibliography.liquid: uses CUSTOM template'
puts '  - bibliography_entry.liquid: uses CUSTOM template (overrides default)'
puts ''

# ==============================================================================
# STEP 6: Show available templates API
# ==============================================================================

puts 'STEP 6: Available templates API'
puts '-' * 70

puts ''
puts 'Default templates available:'
Coradoc::Html::TemplateConfig.available_templates.each do |t|
  path = Coradoc::Html::TemplateConfig.template_path_for(t)
  puts "  #{t}: #{path ? path.basename : 'not found'}"
end
puts ''

# ==============================================================================
# Cleanup
# ==============================================================================

FileUtils.rm_rf(tmpdir)

puts '=' * 70
puts 'DEMONSTRATION COMPLETE'
puts '=' * 70

# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      autoload :Rule, 'coradoc/docx/transform/rule'
      autoload :RuleRegistry, 'coradoc/docx/transform/rule_registry'
      autoload :Context, 'coradoc/docx/transform/context'
      autoload :ToCoreModel, 'coradoc/docx/transform/to_core_model'
      autoload :FromCoreModel, 'coradoc/docx/transform/from_core_model'
      autoload :StyleResolver, 'coradoc/docx/transform/style_resolver'
      autoload :NumberingResolver, 'coradoc/docx/transform/numbering_resolver'
      autoload :OrderedContent, 'coradoc/docx/transform/ordered_content'

      # Element transform rules
      module Rules
        autoload :TextRule, 'coradoc/docx/transform/rules/text_rule'
        autoload :BreakRule, 'coradoc/docx/transform/rules/break_rule'
        autoload :RunRule, 'coradoc/docx/transform/rules/run_rule'
        autoload :HyperlinkRule, 'coradoc/docx/transform/rules/hyperlink_rule'
        autoload :ImageRule, 'coradoc/docx/transform/rules/image_rule'
        autoload :FootnoteRule, 'coradoc/docx/transform/rules/footnote_rule'
        autoload :HeadingRule, 'coradoc/docx/transform/rules/heading_rule'
        autoload :ListItemRule, 'coradoc/docx/transform/rules/list_item_rule'
        autoload :ParagraphRule, 'coradoc/docx/transform/rules/paragraph_rule'
        autoload :TableRule, 'coradoc/docx/transform/rules/table_rule'
        autoload :MathRule, 'coradoc/docx/transform/rules/math_rule'
        autoload :BookmarkRule, 'coradoc/docx/transform/rules/bookmark_rule'
        autoload :StructuredDocumentTagRule,
                 'coradoc/docx/transform/rules/structured_document_tag_rule'
        autoload :SimpleFieldRule,
                 'coradoc/docx/transform/rules/simple_field_rule'
        autoload :ProofErrorRule,
                 'coradoc/docx/transform/rules/proof_error_rule'
      end
    end
  end
end

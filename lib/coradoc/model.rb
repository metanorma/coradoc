# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Model
  end
end

require_relative "model/serialization"

require_relative "model/base"

require_relative "model/attribute_list_attribute"
require_relative "model/named_attribute"
require_relative "model/rejected_positional_attribute"
require_relative "model/attribute_list"
require_relative "model/inline"
require_relative "model/term"
require_relative "model/attached"
require_relative "model/admonition"
require_relative "model/paragraph"
require_relative "model/title"
require_relative "model/section"
require_relative "model/block"
require_relative "model/list"
require_relative "model/list_item"

require_relative "model/bibliography_entry"
require_relative "model/bibliography"
require_relative "model/comment_block"
require_relative "model/comment_line"
require_relative "model/include"
require_relative "model/attribute"
# TODO: validate? validate_named ?
require_relative "model/text_element"
require_relative "model/line_break"
require_relative "model/highlight"
require_relative "model/author"
require_relative "model/revision"
require_relative "model/header"
require_relative "model/document_attributes"
require_relative "model/table_cell"
require_relative "model/table_row"
require_relative "model/table"
require_relative "model/tag"
require_relative "model/list"
require_relative "model/image"
require_relative "model/audio"
require_relative "model/video"
require_relative "model/break"
require_relative "model/document"

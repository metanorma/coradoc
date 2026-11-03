# frozen_string_literal: true

module Coradoc
  module Markdown
    # Represents a kramdown extension
    #
    # Extension syntax: {::extension_name options /}
    # Common extensions:
    #   {::toc} - table of contents
    #   {::options key="value" /} - parser options
    #   {::comment}content{:/} - comment
    #   {::nomarkdown}content{:/} - raw HTML passthrough
    #
    class Extension < Base
      attribute :name, :string
      attribute :options, NamedValue, collection: true, default: []
      attribute :content, :string  # For block extensions with content
      attribute :body, :string     # Alias for content

      prepend Behaviors::Extension
    end
  end
end

# frozen_string_literal: true

module Coradoc
  module Markdown
    # HTML comment in Markdown source (`<!-- text -->`).
    #
    # Markdown has no native comment syntax; HTML comments are the conventional
    # mechanism for non-rendered authoring notes. Both AsciiDoc single-line
    # (`//`) and block (`//// ... ////`) comments collapse to this type.
    class Comment < Base
      attribute :text, :string
    end
  end
end
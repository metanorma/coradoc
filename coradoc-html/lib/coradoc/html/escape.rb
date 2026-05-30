# frozen_string_literal: true

require 'cgi'
require 'json'

module Coradoc
  module Html
    module Escape
      module_function

      def escape_html(text)
        CGI.escapeHTML(text.to_s)
      end

      def escape_attr(value)
        value.to_s
             .gsub('&', '&amp;')
             .gsub('"', '&quot;')
             .gsub('<', '&lt;')
             .gsub('>', '&gt;')
      end

      def safe_json(data)
        json = data.is_a?(String) ? data : JSON.generate(data)
        json.gsub('</script', '<\\/script')
      end
    end
  end
end

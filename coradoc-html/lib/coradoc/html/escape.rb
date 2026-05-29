# frozen_string_literal: true

require 'json'

module Coradoc
  module Html
    module Escape
      module_function

      def escape_html(text)
        text.to_s
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub('\'', '&#39;')
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

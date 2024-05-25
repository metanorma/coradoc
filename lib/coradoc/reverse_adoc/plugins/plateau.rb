module Coradoc::ReverseAdoc
  class Plugin
    # This plugin enhances documents from the PLATEAU project
    # to extract more data.
    #
    # Usage:
    # reverse_adoc -rcoradoc/reverse_adoc/plugins/plateau
    #   --external-images -u raise --output _out/index.adoc index.html
    class Plateau < Plugin
      def name
        "PLATEAU"
      end

      def preprocess_html_tree
        # Remove side menu, so we can generate TOC ourselves
        html_tree_remove_by_css(".sideMenu")

        # Correct non-semantic classes into semantic HTML tags
        html_tree_change_tag_name_by_css(".titledata", "h1")
        html_tree_change_tag_name_by_css(".subtitledata", "h2")
        html_tree_change_tag_name_by_css(".pitemdata", "h3")
        html_tree_change_tag_name_by_css(".sitemdata", "h4")
        html_tree_change_tag_name_by_css('td[bgcolor="#D0CECE"]', "th")

        # Convert table/img caption to become a caption
        html_tree.css(".imagedata").each do |e|
          table = e.parent.next&.children&.first
          if table&.name == "table"
            e.name = "caption"
            table.prepend_child(e)
            next
          end

          img = e.parent.previous&.children&.first
          if img&.name == "img"
            title = e.text.strip
            img["title"] = title
            e.remove
            next
          end

          ### We shouldn't be here
        end

        # Add hooks for H1, H2, H3, H4
        html_tree_add_hook_post_by_css("h1, h2, h3", &method(:handle_headers))
      end

      def handle_headers(node, coradoc, state)
        if coradoc.id.start_with?("toc0_")
          content = coradoc.content.map(&:content).join
          # Special content
          case content
          when "はじめに" # Introduction
            coradoc.style = "abstract" # The older version document has ".preface"
          when "改定の概要" # Revision overview
            coradoc.style = "abstract" # The older version document has ".preface"
          when "参考文献" # Bibliography
            coradoc.style = "bibliography"
          when "改訂履歴" # Document history
            coradoc.style = "appendix"
          else
            warn "Unknown section #{coradoc.content.content}"
          end
        end

        # Remove numbers
        coradoc.content.first.content.sub!(/\A[\d\s.]+/, "")

        coradoc
      end
    end
  end
end

Coradoc::ReverseAdoc.config.plugins << Coradoc::ReverseAdoc::Plugin::Plateau

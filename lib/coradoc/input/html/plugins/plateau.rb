module Coradoc::Input::Html
  class Plugin
    # This plugin enhances documents from the PLATEAU project
    # to extract more data.
    #
    # Usage:
    # reverse_adoc -rcoradoc/input/html/plugins/plateau
    #   --external-images -u raise --output _out/index.adoc index.html
    class Plateau < Plugin
      def name
        "PLATEAU"
      end

      def preprocess_html_tree
        # Let's simplify the tree by removing what's extraneous
        # html_tree_remove_by_css("script, style, img.container_imagebox:not([src])")
        # html_tree_replace_with_children_by_css("div.container_box")
        # html_tree_replace_with_children_by_css("div.col.col-12")
        # html_tree_replace_with_children_by_css(".tabledatatext, .tabledatatextY")
        # html_tree_replace_with_children_by_css("div.row")
        #
        # We can remove that, but it messes up the images and paragraphs.

        # Remove side menu, so we can generate TOC ourselves
        html_tree_remove_by_css(".sideMenu")

        # Correct non-semantic classes into semantic HTML tags
        html_tree_change_tag_name_by_css(".titledata", "h1")
        html_tree_change_tag_name_by_css(".subtitledata", "h2")
        html_tree_change_tag_name_by_css(".pitemdata", "h3")
        html_tree_change_tag_name_by_css(".sitemdata", "h4")
        html_tree_change_tag_name_by_css('td[bgcolor="#D0CECE"]', "th")
        html_tree_change_tag_name_by_css('td[bgcolor="#d0cece"]', "th")
        html_tree_change_tag_name_by_css('.framedata, .frame_container_box', 'aside')
        html_tree_change_tag_name_by_css('.frame2data', 'pre')
        # Assumption that all code snippets in those documents are XML...
        html_tree_change_properties_by_css(".frame2data", class: "brush:xml;")

        # Remove some CSS ids that are not important to us
        html_tree_change_properties_by_css("#__nuxt", id: nil)
        html_tree_change_properties_by_css("#__layout", id: nil)
        html_tree_change_properties_by_css("#app", id: nil)

        # Handle lists of document 02
        html_tree_replace_with_children_by_css(".list_num-wrap")

        # Convert table/img caption to become a caption
        html_tree.css(".imagedata").each do |e|
          table = e.parent.next&.children&.first
          if table&.name == "table"
            e.name = "caption"
            table.prepend_child(e)
            next
          end

          img = e.parent.previous&.children&.first
          if img&.name == "img" && img["src"]
            title = e.text.strip
            img["title"] = title
            e.remove
            next
          end
        end

        # Add hooks for H1, H2, H3, H4
        html_tree_add_hook_post_by_css("h1, h2, h3", &method(:handle_headers))
        html_tree_add_hook_post_by_css("h4", &method(:handle_headers_h4))

        # Table cells aligned to center
        html_tree_change_properties_by_css(".tableTopCenter", align: "center")

        # Handle non-semantic lists and indentation
        html_tree_add_hook_pre_by_css ".text2data" do |node,|
          text = html_tree_process_to_adoc(node).strip
          next "" if text.empty? || text == "\u3000"

          if text.start_with?(/\d+\./)
            text = text.sub(/\A\d+.\s*/, "")
            ".. #{text}\n"
          else
            text = text.gsub(/^/, "** ")
            "\n\n//-PT2D\n#{text}\n//-ENDPT2D\n\n"
          end
        end

        (3..4).each do |i|
          html_tree_add_hook_pre_by_css ".text#{i}data" do |node,|
            text = html_tree_process_to_adoc(node).strip
            next "" if text.empty? || text == "\u3000"

            text = text.strip.gsub(/^/, "#{'*' * i} ")
            "\n\n//-PT#{i}D\n#{text}\n//-ENDPT#{i}D\n\n"
          end
        end

        (2..3).each do |i|
          html_tree_add_hook_pre_by_css ".text#{i}data_point ul" do |node,|
            text = html_tree_process_to_adoc(node.children.first.children).strip

            "#{'*' * i} #{text}\n"
          end
        end

        (1..20).each do |i|
          html_tree_add_hook_pre_by_css ".numtextdata_num .list_num#{i}" do |node,|
            text = html_tree_process_to_adoc(node).strip

            "[start=#{i}]\n. #{text}\n"
          end
        end

        # html_tree_preview
      end

      IM = /[A-Z0-9]{1,3}/

      def handle_headers(node, coradoc, state)
        content = coradoc.content.map(&:content).join

        if %w[toc0 toc_0].any? { |i| coradoc.id&.start_with?(i) }
          # Special content
          case content.strip
          when "はじめに" # Introduction
            coradoc.style = "abstract" # The older version document has ".preface"
            coradoc.level_int = 1
          when "改定の概要" # Revision overview
            coradoc.style = "abstract" # The older version document has ".preface"
            coradoc.level_int = 1
          when "参考文献" # Bibliography
            coradoc.style = "bibliography"
            coradoc.level_int = 1
          when "改訂履歴" # Document history
            coradoc.style = "appendix"
            coradoc.level_int = 1
          when "0　概要" # Overview
            coradoc.style = "abstract" # I'm not sure this is correct
            coradoc.level_int = 1
          when "索引" # Index
            coradoc.style = "index" # I'm not sure this is correct
            coradoc.level_int = 1
          else
            warn "Unknown section #{content.inspect}"
          end
        end

        if node.name == "h1"
          if content.start_with?("Annex")
            coradoc.style = "appendix"
            coradoc.content.first.content.sub!(/\AAnnex [A-Z]/, "")
          end
        end

        # Remove numbers
        coradoc.content.first.content.sub!(/\A(#{IM}\.)*#{IM}[[:space:]]/, "")

        coradoc
      end

      def handle_headers_h4(node, coradoc, state)
        title = Coradoc.strip_unicode(coradoc.content.first.content)
        case title
        when /\A\(\d+\)(.*)/
          coradoc.level_int = 4
          coradoc.content.first.content = $1.strip
          coradoc
        when /\A\d+\)(.*)/
          coradoc.level_int = 5
          coradoc.content.first.content = $1.strip
          coradoc
        when /\A#{IM}\.#{IM}\.#{IM}\.#{IM}(.*)/
          coradoc.level_int = 4
          coradoc.content.first.content = $1.strip
        else
          if title.empty?
            # Strip instances of faulty empty paragraphs
            nil
          else
            ["// FIXME\n", coradoc]
          end
        end
      end

      def postprocess_asciidoc_string
        str = self.asciidoc_string

        ### Custom indentation handling
        # If there's a step up, add [none]
        str = str.gsub(%r{\s+//-ENDPT2D\s+//-PT3D\s+}, "\n[none]\n")
        str = str.gsub(%r{\s+//-ENDPT2D\s+//-PT4D\s+}, "\n[none]\n")
        str = str.gsub(%r{\s+//-ENDPT3D\s+//-PT4D\s+}, "\n[none]\n")
        # Collapse blocks of text[2,3]data
        str = str.gsub(%r{\s+//-ENDPT[234]D\s+//-PT[234]D\s+}, "\n\n")
        # In the beginning, add [none]
        str = str.gsub(%r{\s+//-PT[234]D\s+}, "\n\n[none]\n")
        # If following with another list, ensure we readd styling
        str = str.gsub(%r{\s+//-ENDPT[234]D\s+\*}, "\n\n[disc]\n*")
        # Otherwise, clean up
        str = str.gsub(%r{\s+//-ENDPT[234]D\s+}, "\n\n")

        self.asciidoc_string = str
      end
    end
  end
end

Coradoc::Input::Html.config.plugins << Coradoc::Input::Html::Plugin::Plateau

# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Bypass < Base
          INSTANCE = new

          def to_coradoc(node, state = {})
            treat_children_coradoc(node, state)
          end
        end

        register :document, Bypass::INSTANCE
        register :html,     Bypass::INSTANCE
        register :body,     Bypass::INSTANCE
        register :span,     Bypass::INSTANCE
        register :thead,    Bypass::INSTANCE
        register :tbody,    Bypass::INSTANCE
        register :tfoot,    Bypass::INSTANCE
        register :abbr,     Bypass::INSTANCE
        register :acronym,  Bypass::INSTANCE
        register :address,  Bypass::INSTANCE
        register :applet,   Bypass::INSTANCE
        register :map,      Bypass::INSTANCE
        register :area,     Bypass::INSTANCE
        register :bdi,      Bypass::INSTANCE
        register :bdo,      Bypass::INSTANCE
        register :big,      Bypass::INSTANCE
        register :button,   Bypass::INSTANCE
        register :canvas,   Bypass::INSTANCE
        register :data,     Bypass::INSTANCE
        register :datalist, Bypass::INSTANCE
        register :del,      Bypass::INSTANCE
        register :ins,      Bypass::INSTANCE
        register :dfn,      Bypass::INSTANCE
        register :dialog,   Bypass::INSTANCE
        register :embed,    Bypass::INSTANCE
        register :fieldset, Bypass::INSTANCE
        register :font,     Bypass::INSTANCE
        register :footer,   Bypass::INSTANCE
        register :form,     Bypass::INSTANCE
        register :frame,    Bypass::INSTANCE
        register :frameset, Bypass::INSTANCE
        register :header,   Bypass::INSTANCE
        register :iframe,   Bypass::INSTANCE
        register :input,    Bypass::INSTANCE
        register :label,    Bypass::INSTANCE
        register :legend,   Bypass::INSTANCE
        register :main,     Bypass::INSTANCE
        register :menu,     Bypass::INSTANCE
        register :menulist, Bypass::INSTANCE
        register :meter,    Bypass::INSTANCE
        register :nav,      Bypass::INSTANCE
        register :noframes, Bypass::INSTANCE
        register :noscript, Bypass::INSTANCE
        register :object,   Bypass::INSTANCE
        register :optgroup, Bypass::INSTANCE
        register :option,   Bypass::INSTANCE
        register :output,   Bypass::INSTANCE
        register :param,    Bypass::INSTANCE
        register :picture,  Bypass::INSTANCE
        register :progress, Bypass::INSTANCE
        register :ruby,     Bypass::INSTANCE
        register :rt,       Bypass::INSTANCE
        register :rp,       Bypass::INSTANCE
        register :s,        Bypass::INSTANCE
        register :select,   Bypass::INSTANCE
        register :small,    Bypass::INSTANCE
        register :strike,   Bypass::INSTANCE
        register :details,  Bypass::INSTANCE
        register :section,  Bypass::INSTANCE
        register :summary,  Bypass::INSTANCE
        register :svg,      Bypass::INSTANCE
        register :template, Bypass::INSTANCE
        register :textarea, Bypass::INSTANCE
        register :track,    Bypass::INSTANCE
        register :u,        Bypass::INSTANCE
        register :wbr,      Bypass::INSTANCE
      end
    end
  end
end

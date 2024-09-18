warn <<~WARN
  Deprecated: coradoc/reverse_adoc has been renamed to coradoc/input/html.
  | Please update your references from:
  |   require 'coradoc/reverse_adoc'
  | To:
  |   require 'coradoc/input/html'
  |
  | You are referencing an old require here:
  |   #{caller.join("\n|   ")}
  |
  | Please also ensure that you replace all references to Coradoc::ReverseAdoc
  | in your code with Coradoc::Input::HTML.
WARN

require 'coradoc'
require 'coradoc/input/html'

Coradoc::ReverseAdoc = Coradoc::Input::HTML

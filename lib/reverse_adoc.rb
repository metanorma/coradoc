warn <<~WARN
  Deprecated: reverse_adoc has been merged into coradoc gem.
  | Please update your references from:
  |   require 'reverse_adoc'
  | To:
  |   require 'coradoc/input/html'
  |
  | You are referencing an old require here:
  |   #{caller.join("\n|   ")}
  |
  | You should also replace 'reverse_adoc' with 'coradoc' in your gem dependencies.
  | reverse_adoc 2.0.0 will be kept with 'coradoc' as the only dependency.
  |
  | Please also ensure that you replace all references to ReverseAdoc in your code
  | with Coradoc::Input::HTML.
WARN

require "coradoc/input/html"

ReverseAdoc = Coradoc::Input::HTML

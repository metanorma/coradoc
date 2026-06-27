# frozen_string_literal: true

require 'coradoc'
require_relative 'coradoc/mirror'

# Side-effect: registers format modules with Coradoc registry.
# These must use require (not autoload) because they have load-time side effects.
require_relative 'coradoc/mirror/mirror_json_format'
require_relative 'coradoc/mirror/mirror_yaml_format'

# Ensure Coradoc error classes are loaded (autoloaded via Coradoc::Error).
Coradoc::Error

# Proposal: Support for Recursive/Self-Referential Types in lutaml-model

## Problem Description

When a lutaml-model class has an attribute that references itself (recursive/self-referential type), calling `to_hash` or `to_json` causes a `SystemStackError` (stack level too deep).

### Example

```ruby
class InlineElement < Lutaml::Model::Serializable
  attribute :format_type, :string
  attribute :content, :string

  # This causes infinite recursion in to_hash
  attribute :nested_elements, InlineElement, collection: true
end

# This throws SystemStackError
element = InlineElement.new(format_type: "bold", content: "text")
element.to_hash  # => SystemStackError: stack level too deep
```

## Root Cause Analysis

The error occurs in `Lutaml::Model::KeyValue::Transformation.compile_rules` when the transformation tries to recursively compile mapping rules for nested types. Since `InlineElement` references itself, the compilation never terminates.

### Stack Trace (truncated)

```
/lutaml/model/key_value/transformation.rb:37:in `block in compile_rules': stack level too deep (SystemStackError)
	from /lutaml/model/key_value/transformation.rb:36:in `each'
	from /lutaml/model/key_value/transformation.rb:36:in `compile_rules'
	from /lutaml/model/transformation.rb:39:in `initialize'
	from /lutaml/model/key_value/transformation.rb:208:in `new'
	from /lutaml/model/key_value/transformation.rb:208:in `build_child_transformation'
	from /lutaml/model/key_value/transformation.rb:108:in `compile_mapping_rule'
	from /lutaml/model/key_value/transformation.rb:37:in `block in compile_rules'
	... 8326 levels...
```

## Proposed Solution

### Option A: Track Visited Types During Rule Compilation

Add a type tracking mechanism to prevent infinite recursion during rule compilation:

```ruby
module Lutaml::Model::KeyValue::Transformation
  def compile_rules
    # Track types currently being compiled
    @compiling_types ||= Set.new

    mapping.rules.each do |rule|
      next unless rule.custom_methods[:to].nil?

      # Check for recursive reference
      if rule.type.is_a?(Class) && rule.type < Lutaml::Model::Serializable
        type_name = rule.type.name

        if @compiling_types.include?(type_name)
          # Skip recursive reference - will be handled at runtime
          next
        end

        @compiling_types.add(type_name)
        compile_mapping_rule(rule)
        @compiling_types.delete(type_name)
      else
        compile_mapping_rule(rule)
      end
    end
  end
end
```

### Option B: Lazy Evaluation of Nested Types

Defer the compilation of nested type rules until they are actually needed:

```ruby
def compile_mapping_rule(rule)
  # For recursive types, create a lazy evaluator
  if recursive_type?(rule.type)
    define_singleton_method("transform_#{rule.name}") do |value, doc|
      next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      value.map do |item|
        # Compile lazily at runtime
        item.to_hash
      end
    end
  else
    # Existing behavior
    build_child_transformation(rule.type)
  end
end
```

### Option C: Add `recursive: true` Option

Allow users to mark attributes as recursive, signaling lutaml-model to handle them specially:

```ruby
class InlineElement < Lutaml::Model::Serializable
  attribute :format_type, :string
  attribute :content, :string

  # Mark as recursive - lutaml-model handles serialization specially
  attribute :nested_elements, InlineElement, collection: true, recursive: true
end
```

## Workaround for Current Version

Users can currently work around this by:

1. Using instance variable inspection instead of `to_hash`:
```ruby
def to_custom_hash
  result = {}
  instance_variables.each do |var|
    key = var.to_s.delete_prefix("@")
    value = instance_variable_get(var)
    result[key] = normalize(value)
  end
  result
end
```

2. Avoiding recursive type definitions and using a separate containment model

## Impact

This issue affects any document model that supports:
- Nested inline formatting (bold containing italic, etc.)
- Tree structures (sections containing sections)
- Graph-like data structures

## Related Classes in coradoc

- `Coradoc::CoreModel::InlineElement` - nested inline formatting
- `Coradoc::CoreModel::StructuralElement` - sections containing sections

---

Please let me know if you need more details or a pull request implementation.

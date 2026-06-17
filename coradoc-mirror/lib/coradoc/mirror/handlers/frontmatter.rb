# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Handles FrontmatterBlock → frontmatter node.
      #
      # The +data+ hash passes through with one deep conversion:
      # Date/Time/DateTime values become ISO 8601 strings, Symbols become
      # strings. Ruby's +JSON.dump+ cannot serialize these natively, so this
      # is the single MECE place where type narrowing happens. On the reverse
      # path (Mirror → CoreModel), JSON-native types populate +data+ directly.
      module Frontmatter
        def self.call(element, *)
          Node::Frontmatter.new(
            schema: element.schema,
            data: JsonifiableHash.call(element.data || {})
          )
        end

        # Recursive hash/array walker that narrows YAML-rich types to
        # JSON-native types (Date/Time/DateTime → ISO 8601 string,
        # Symbol → string). String/Integer/Float/Boolean/nil pass through.
        module JsonifiableHash
          class << self
            def call(obj)
              case obj
              when Hash then obj.transform_values { |v| call(v) }
              when Array then obj.map { |v| call(v) }
              when Date, Time, DateTime then obj.iso8601
              when Symbol then obj.to_s
              else obj
              end
            end
          end
        end
      end
    end
  end
end

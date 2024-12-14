require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "fenced code blocks" do
    markdown_example 119, %q(
```
<
 >
```
), [
  {code_block: [{ln: "<"}, {ln: " >"}]}
]

    markdown_example 120, %q(
~~~
<
 >
~~~
), [
  {code_block: [{ln: "<"}, {ln: " >"}]}
]

    markdown_example 121, %q(
``
foo
``
  ), [
    {p: [{ln: "``"}, {ln: "foo"}, {ln: "``"}]} # XXX: inline
  ]

    markdown_example 122, %q(
```
aaa
~~~
```
  ), [
    {code_block: [{ln: "aaa"}, {ln: "~~~"}]}
  ]

    markdown_example 123, %q(
~~~
aaa
```
~~~
), [
  {code_block: [{ln: "aaa"}, {ln: "```"}]}
]

    markdown_example 124, %q(
````
aaa
```
``````
), [
  {code_block: [{ln: "aaa"}, {ln: "```"}]}
]

    markdown_example 125, %q(
~~~~
aaa
~~~
~~~~
), [
  {code_block: [{ln: "aaa"}, {ln: "~~~"}]}
]

    markdown_example 126, %q(
```
), [
        {code_block: []}
      ]

    markdown_example 127, %q(
`````

```
aaa
), [
        {code_block: [{ln: ""}, {ln: "```"}, {ln: "aaa"}]}
      ]

    markdown_example 128, %q(
> ```
> aaa

bbb
  ), [
    {block_quote: {code_block: [{ln: "aaa"}]}},
    {p: {ln: "bbb"}},
  ]

    markdown_example "parses example 128 but with a closed fence", %q(
> ```
> aaa
> ```

bbb
  ), [
    {block_quote: {code_block: [{ln: "aaa"}]}},
    {p: {ln: "bbb"}},
  ]

    markdown_example 129, %q(
```

  
```
), [
  {code_block: [{ln: ""}, {ln: "  "}]},
]

    markdown_example 130, %q(
```
```
), [
  {code_block: []},
]

    markdown_example 131, %q(
 ```
 aaa
aaa
```
), [
  {code_block: [{ln: "aaa"}, {ln: "aaa"}]},
], strip: false # deletes significant initial indentation

    markdown_example 132, %q(
  ```
aaa
  aaa
aaa
  ```
), [
  {code_block: [{ln: "aaa"}, {ln: "aaa"}, {ln: "aaa"}]},
], strip: false # deletes significant initial indentation

    markdown_example 133, %q(
   ```
   aaa
    aaa
  aaa
   ```
), [
  {code_block: [{ln: "aaa"}, {ln: " aaa"}, {ln: "aaa"}]},
], strip: false # deletes significant initial indentation

    markdown_example 134, %q(
    ```
    aaa
    ```
), [
        {code_block: [{ln: "```"}, {ln: "aaa"}, {ln: "```"}]},
      ], strip: false # deletes significant indentation for the block

    markdown_example 135, %q(
```
aaa
  ```
), [
  {code_block: [{ln: "aaa"}]},
]

    markdown_example 136, %q(
   ```
aaa
  ```
), [
  {code_block: [{ln: "aaa"}]},
]

    markdown_example 137, %q(
```
aaa
    ```
), [
{code_block: [{ln: "aaa"}, {ln: "    ```"}]},
      ]

    markdown_example 135, %q(
``` ```
aaa
), [
  {p: [{ln: "``` ```"}, {ln: "aaa"}]}
]

    markdown_example 139, %q(
~~~~~~
aaa
~~~ ~~
), [
        {code_block: [{ln: "aaa"}, {ln: "~~~ ~~"}]},
      ]

    markdown_example 140, %q(
foo
```
bar
```
baz
), [
  {p: {ln: "foo"}},
  {code_block: [{ln: "bar"}]},
  {p: {ln: "baz"}},
]

    markdown_example 141, %q(
foo
---
~~~
bar
~~~
# baz
), [
        {heading: "---", text: {ln: "foo"}},
        {code_block: [{ln: "bar"}]},
        {heading: "#", text: "baz"},
      ]

    markdown_example 142, %q(
```ruby
def foo(x)
  return 3
end
```
), [
  {code_block: [{ln: "def foo(x)"}, {ln: "  return 3"}, {ln: "end"}], info: "ruby"},
]

    markdown_example 143, %q(
~~~~    ruby startline=3 $%@#$
def foo(x)
  return 3
end
~~~~~~~
), [
        {code_block: [{ln: "def foo(x)"}, {ln: "  return 3"}, {ln: "end"}], info: "    ruby startline=3 \$%@\#\$"},
      ]

    markdown_example 144, %q(
````;
````
), [
  {code_block: [], info: ";"},
]

    markdown_example 145, %q(
``` aa ```
foo
), [
  {p: [{ln: "``` aa ```"}, {ln: "foo"}]} # XXX: inline
]

    markdown_example 146, %q(
~~~ aa ``` ~~~
foo
~~~
), [
  {code_block: [{ln: "foo"}], info: " aa ``` ~~~"},
]

    markdown_example 147, %q(
```
``` aaa
```
), [
  {code_block: [{ln: "``` aaa"}]},
]
  end
end

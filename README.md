# Coradoc

Coradoc is a modern Parser for Asciidoc document. It defines a grammar for
AsciiDoc, and then build the Parser for that grammar.

Once the document is parsed, it provides a pure ruby object `Coradoc::Document`,
which can used to customize the document in easiest way.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "coradoc"
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install coradoc
```

## Development

We are following Sandi Metz's Rules for this gem, you can read the
[description of the rules here][sandi-metz] All new code should follow these
rules. If you make changes in a pre-existing file that violates these rules you
should fix the violations as part of your contribution.

### Setup

Clone the repository.

```sh
git clone https://github.com/metanorma/coradoc.git
```

Setup your environment in docker

```sh
make setup
```

Run the test suite

```sh
make test
```


## Usage from command line

### Converting a document

```bash
$ coradoc help convert
$ coradoc convert file.html -o file.adoc
```

## Usage from Ruby

### Parsing a document

To parse any AsciiDoc, we can use the following:

```ruby
Coradoc::Parser.parse(sample_asciidoc)
```

This interface will return the abstract syntax tree.

### Converting a document

To convert any document of a supported format (right now: `.html`, `.adoc`, `.docx`) to any supported
format (right now: `.adoc`), you can execute:

```ruby
Coradoc::Converter.("input.html", "output.adoc")
```

The converters are chosen based on file extension, but you can select a converter manually like so:

```ruby
Coradoc::Converter.("input", "output", input_processor: :html, output_processor: :adoc)
```

Some converters may support additional options, which can likewise be passed as keyword arguments:

```ruby
Coradoc::Converter.(
  "input.html", "output.adoc",
  input_options: { external_images: true, split_sections: 2 }
)
```

It is also possible to pass IO objects instead of filenames. By default, if an argument is not
provided, it defaults to STDIN/STDOUT. Note that not all combinations of formats and converter
options are supported in this mode.

### Legacy README for converting from HTML to AsciiDoc (formerly reverse_adoc)

See: [Coradoc::Input::HTML README](https://github.com/metanorma/coradoc/blob/main/lib/input/html/README.adoc)

[sandi-metz]: http://robots.thoughtbot.com/post/50655960596/sandi-metz-rules-for-developers

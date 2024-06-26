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


## Usages

### Parsing a document

To parse any AsciiDoc, we can use the following:

```ruby
Coradoc::Parser.parse(sample_asciidoc)
```

This interface will return the abstract syntax tree.

### Converting from HTML to AsciiDoc (reverse_adoc)

See: [reverse_adoc README](https://github.com/metanorma/coradoc/blob/main/lib/coradoc/reverse_adoc/README.adoc)

[sandi-metz]: http://robots.thoughtbot.com/post/50655960596/sandi-metz-rules-for-developers

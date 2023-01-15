# Coradoc

Ignore it for now!

## Parsing a document

```ruby
file = "sample.adoc"
document = Coradoc::Parser.parse(file)
```

Here are the attributes it should contains

**Standard Doc**

```yml
- bibdata
- boilerplate
- preface
- sections
- annex: AnnexA
- annex: AnnexB
- annex: AnnexC
- annex: AnnexD
- annex: _extraneous_information
- bibliography

# Additional
- extension
- preface
- indexsect:
- type
- version
```

**Bibdata**

```yml
- title: []
- docidentifier: []
- docnumber
- contributor:
    - role: []
    - organization.name
    - organization.abbreviation

- edition
- version
- language
- script
- status
- copyright
- ext

```

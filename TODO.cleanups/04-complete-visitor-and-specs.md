# 04: Complete Visitor dispatch + add missing specs

## Problem
1. `CoreModel::Metadata`, `CoreModel::MetadataEntry`, `CoreModel::ElementAttribute`
   are not in the Visitor dispatch — they fall through to `visit_unknown`
2. `Coradoc.strip_unicode` has no specs
3. `Registry#each_value`, `#each_key`, `#options_for` have no specs
4. `Registry#process` error_label not tested in registry_spec.rb

## Changes
1. Add visitor dispatch for Metadata, MetadataEntry, ElementAttribute
2. Add specs for strip_unicode
3. Add specs for Registry iteration and options methods
4. Add specs for Metadata, MetadataEntry, ElementAttribute visitor dispatch

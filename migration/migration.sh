#!/bin/bash

set -euxo pipefail # Abort on error

GH_PREFIX="$1"

rm -rf coradoc reverse_adoc reverse_adoc_post_migration

# The resulting repository.
git clone $GH_PREFIX/metanorma/coradoc/ coradoc
# The reverse_adoc repo will need to have been amended - it will need to have no
# duplicate files to the Coradoc repo, so that we could merge both cleanly.
git clone $GH_PREFIX/metanorma/reverse_adoc/ reverse_adoc
# Post migration repo, to preserve the Gem name and provide a smooth upgrade path.
git clone $GH_PREFIX/metanorma/reverse_adoc/ reverse_adoc_post_migration

pushd reverse_adoc
  mkdir lib/coradoc
  git mv lib/reverse_adoc* lib/coradoc/
  ALL_SPEC_FILES=`ls -d spec/*` # So that we skip spec/reverse_adoc from this calculation
  mkdir -p spec/reverse_adoc
  git mv $ALL_SPEC_FILES spec/reverse_adoc/
  git mv README.adoc LICENSE.txt lib/coradoc/reverse_adoc/

  git commit -m 'Merger: Move reverse_adoc files to not conflict with Coradoc files'

  sed -i 's|require "reverse_adoc|require "coradoc/reverse_adoc|g' exe/* `find spec/ -name \*.rb`
  sed -i 's/ReverseAdoc/Coradoc::ReverseAdoc/g' exe/* `find lib/ spec/ -name \*.rb` lib/coradoc/reverse_adoc/README.adoc
  sed -i 's|"spec/assets/|"spec/reverse_adoc/assets/|g' `find spec/ -name \*.rb`
  sed -i 's|require_relative "reverse_adoc/version"|require_relative "../coradoc"|g' lib/coradoc/reverse_adoc.rb
  sed -i 's|"spec", "support"|"spec", "reverse_adoc", "support"|g' spec/reverse_adoc/spec_helper.rb

  git add .
  git commit -m 'Merger: Rename ReverseAdoc to Coradoc::ReverseAdoc'

  git rm lib/coradoc/reverse_adoc/version.rb
  git rm .rubocop.yml
  git rm .hound.yml
  git rm Gemfile
  git rm Rakefile # Needs manual merge
  git rm .gitignore # Needs manual merge
  git rm .github/workflows/rake.yml
  git rm .github/workflows/release.yml

  git commit -m 'Merger: Remove files that are not applicable anymore'
popd

pushd coradoc
  git fetch ../reverse_adoc
  git merge --allow-unrelated-histories FETCH_HEAD -m 'Merger: Merge reverse_adoc repository into coradoc'

  cat *.gemspec  | grep dependency | sed -r 's/ s\./ spec./' | sort | uniq | grep -v coradoc > ../combined_dependencies
  cat coradoc.gemspec | grep -v dependency | grep -Ev '^end' > ../new_gemspec
  cat ../combined_dependencies >> ../new_gemspec
  echo end >> ../new_gemspec

  git rm reverse_adoc.gemspec
  mv ../new_gemspec coradoc.gemspec
  git add coradoc.gemspec
  git commit -m 'Merger: Combine gemspec files'

  git rm spec/reverse_adoc/spec_helper.rb
  cp ../spec_helper_coradoc.rb spec/spec_helper.rb
  git add spec/spec_helper.rb
  git commit -m 'Merger: Combine spec helpers'

  sed -i 's/generic-rake.yml/libreoffice-rake.yml/g' .github/workflows/rake.yml
  git add .github/workflows/rake.yml
  git commit -m 'Merger: Combine GitHub Actions'
popd

pushd reverse_adoc_post_migration
  find -type f | grep -Fv 'release.yml' | grep -Fv '.git/' | xargs git rm
  cp ../README_reverse_adoc_post_migration.adoc README.adoc
  cp ../reverse_adoc_post_migration.gemspec reverse_adoc.gemspec
  git add README.adoc reverse_adoc.gemspec
  git commit -m 'Merger: Replace reverse_adoc with a stub gem'
popd

# Ensure everything works correctly
pushd coradoc
  bundle install
  bundle exec rake
popd

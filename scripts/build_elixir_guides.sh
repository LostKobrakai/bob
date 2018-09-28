#!/bin/bash

# $1 = event
# $2 = ref

set -e -u

HEXPM=$BOB_FASTLY_SERVICE_HEXPM

script_dir=$(dirname $(pwd)/${BASH_SOURCE})

source ${script_dir}/utils.sh

# $1 = ref
function push {
  rm -rf elixir || true
  git clone git://github.com/elixir-lang/elixir-lang.github.com.git --quiet --branch master
  cd elixir-lang.github.com/_epub

  rm .tool-versions || true
  asdf local erlang 20.0
  asdf local elixir 1.5.0

  mix deps.get
  mix compile
  mix epub

  for file in *.epub
  do
    echo $file
    aws s3 cp "${file}" "s3://s3.hex.pm/guides/elixir/${file}" --content-type "application/epub+zip" --cache-control "public,max-age=3600" --metadata '{"surrogate-key":"guides","surrogate-control":"public,max-age=604800"}'
  done

  fastly_purge $HEXPM guides
}

if [ "$1" == "push" ] && [ "$2" == "master" ]; then
  push "$2"
fi

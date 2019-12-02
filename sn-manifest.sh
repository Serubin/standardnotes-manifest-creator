#!/bin/bash

flag_force=0
flag_help=0
flag_submodules=0

repo=""
target=""
type="Component"
area=""
version=""
name=""
id=""

# process arguments
set -- $(getopt "hfst:a:v:i::n" "$@")

while [ $# -gt 0 ]; do
    case "$1" in
      (-h) flag_help=1            ;;
      (-f) flag_force=1           ;;
      (-s) flag_submodules=1      ;;
      (-t) type="$2";       shift ;;
      (-a) area="$2";       shift ;;
      (-v) version="$2";    shift ;;
      (-i) id="$2";         shift ;;
      (-n) name="$2";       shift ;;
      (--) shift; break           ;;
      (*)  break                  ;;
    esac
    shift
done

repo=${1}
target=${2}

if [[ ${repo} == "" ]]; then
  echo "Exentension repo required. Exiting."
  exit
fi

if [[ ${type} == "" ]]; then
  echo "Extension type required. Exiting."
  exit
fi

if [[ ${area} == "" ]]; then
  echo "Extension area required. Exiting."
  exit
fi

function printHelp () {
  # Help options
    echo "usage: ./install -hf"
    echo "    -h                        Usage"
    echo "    -f                        Force manifest install on any repo - will overwrite existing ext.json"
    echo "    -t                        Extension type: 'Component', 'Theme', etc"
    echo "    -a                        Extension area: 'editor-editor', 'Theme', etc"
    echo "    -v                        Extension Version: defaults to package.json"
    echo "    -i                        Identifier: defaults to net.serubin.<repo-tail>"
    echo "    -n                        Name: defaults to Repo Tail"
    echo "    -s                        Use submodules"

    exit
}

##
# clones git repo - checks if repo is sn-ext
function cloneRepo () {
  if [[ ! ${repo} != "https://github.com/sn-extensions*" ]] && [[ ${flag_force} != "1" ]]; then
    echo "This is not an Standard Note Extension - add -f to override"
    exit
  fi

  if [[ ${flag_submodules} == "1" ]]; then
    git submodule add ${repo} ${target}
  else
    git clone ${repo} ${target}
  fi
}

##
# generates manifest file contents
# @return manifest
function generateManifest () {

  human_name=$(echo ${name} | tr '-' ' ' | sed -e 's/\b\(.\)/\u\1/g')
  cat >> ${target}/ext.json << EOL
    {
        "identifier": "org.sn-ext.${name}",
        "name": "${human_name}",
        "content_type": "SN|${type}",
        "area": "${area}",
        "version": "${version}",
        "url": "/extensions/${name}/",
        "github": "${repo}"
    }
EOL
}

##
# Gets name from git url
# @param url
# @returns name
function getRepoName () {
  url_split=($(echo $1 | tr '/' ' '))
  echo $(echo ${url_split[${#url_split[@]}-1]} | sed -e 's/.git//') # Strip .git
}

##
# Simple attribute grabber
# @param file
# @param attribute
# @param attribute value
function getJsonAttr () {
  file=$1
  attr=$2
  echo $(cat ${target}/${file} | grep "${attr}" | xargs | sed -e "s/${attr}: //" | sed -e "s/,//")
}

if [[ ${flag_help} == "1" ]]; then
  printHelp
fi


if [[ ${name} == "" ]]; then
  name=$(getRepoName ${repo})
fi

if [[ ${target} == "" ]]; then
  target=${name}
fi
cloneRepo

if [[ ${version} == "" ]]; then
  version=$(getJsonAttr "package.json" "version")
fi
if [[ ${id} == "" ]]; then
  id=$(getJsonAttr "package.json" "name")
fi

generateManifest


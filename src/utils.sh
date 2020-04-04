#!/usr/bin/env bash

# see https://stackoverflow.com/a/246128/5354298
get_script_dir() { echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }
SCRIPT_DIR=$(get_script_dir)
START_DIR=$(pwd)

# TODO: ../allene is always supposed to pass these variables. Can we get rid of this section?
[ -z "$ALLENE_CACHE" ] && echo "ALLENE_CACHE not set" >/dev/stderr
[ -z "$PKG_INFO_CACHE" ] && echo "PKG_INFO_CACHE not set" >/dev/stderr
[ -z "$PEER_DEPENDENCIES_BY_DEPENDENT_F" ] && echo "PEER_DEPENDENCIES_BY_DEPENDENT_F not set" >/dev/stderr
[ -z "$PEER_DEPENDENTS_BY_DEPENDENCY_F" ] && echo "PEER_DEPENDENTS_BY_DEPENDENCY_F not set" >/dev/stderr

on_error() {
  if [ -e "$PEER_DEPENDENCIES_BY_DEPENDENT_F" ]; then
    rm "$PEER_DEPENDENCIES_BY_DEPENDENT_F"
  fi
}
cleanup_complete_utils=0
cleanup() {
  cd "$START_DIR" || return
  if [ -e "$PEER_DEPENDENTS_BY_DEPENDENCY_F" ]; then
    rm "$PEER_DEPENDENTS_BY_DEPENDENCY_F"
  fi
  cleanup_complete_utils=1
}
# Based on http://linuxcommand.org/lc3_wss0140.php
# and https://codeinthehole.com/tips/bash-error-reporting/
error_exit() {
  #	----------------------------------------------------------------
  #	Function for exit due to fatal program error
  #		Accepts 1 argument:
  #			string containing descriptive error message
  #	----------------------------------------------------------------

  on_error

  read -r line file <<<"$(caller)"
  if [ ! -e "$file" ]; then
    file="$SCRIPT_DIR/$file"
  fi
  echo "" 1>&2
  echo "ERROR: file $file, line $line" 1>&2
  if [ ! "$1" ] && [ -e "$file" ]; then
    sed "${line}q;d" "$file" 1>&2
  else
    echo "${1:-"Unknown Error"}" 1>&2
  fi
  echo "" 1>&2

  # TODO: should error_exit call cleanup?
  #       The EXIT trap already calls cleanup, so
  #       calling it here means calling it twice.
  if [ ! $cleanup_complete_utils ]; then
    cleanup
  fi
  exit 1
}
trap error_exit ERR
trap cleanup EXIT INT QUIT TERM
shopt -s globstar
shopt -s extglob

if [ -z "$ALLENE_PACMAN_CLI" ]; then
  ALLENE_PACMAN_CLI="npm"
fi

# from https://stackoverflow.com/a/8574392
contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

get_pkg_batches() {
  reqs_by_dep="$1"
  passed="$2"
  if [ -z "$passed" ]; then
    passed='[]'
  fi
  tranches="$3"
  if [ -z "$tranches" ]; then
    tranches='[]'
  fi
  reqs_by_dep_length=$(echo "$reqs_by_dep" | jq 'length')
  tranches=$(echo "$reqs_by_dep" | jq --argjson tranches "$tranches" --argjson passed "$passed" \
    '$tranches + [
        map(
          to_entries |
          map(select((.value - $passed | length) == 0))
        ) |
        flatten |
        map(.key) - $passed
      ]')
  passed=$(echo "$reqs_by_dep" |
    jq --argjson passed "$passed" \
      'map(
      to_entries |
      map(select((.value - $passed | length) == 0))
    ) |
    flatten |
    map(.key) + $passed |
    unique')
  passed_length=$(echo "$passed" | jq 'length')
  if [[ "$passed_length" -lt "$reqs_by_dep_length" ]]; then
    get_pkg_batches "$reqs_by_dep" "$passed" "$tranches"
  else
    echo "$tranches"
  fi
}

get_pkg_info() {
  pkg="$1"
  pkg_info='{}'
  pkg_info_cache_f="$PKG_INFO_CACHE"/"$pkg".json
  mkdir -p "$(dirname "$pkg_info_cache_f")"
  if [ -e "$pkg_info_cache_f" ]; then
    cat "$pkg_info_cache_f"
    return
  fi
  if [ "$ALLENE_PACMAN_CLI" == "yarn" ]; then
    pkg_info=$(yarn info --json "$pkg" | jq -r '.data')
  else
    pkg_info=$(npm info --json "$pkg")
  fi
  touch "$pkg_info_cache_f"
  echo "$pkg_info" | tee "$pkg_info_cache_f"
}

get_pkg_json_paths() {
  ls -1 packages/node_modules/!(available)/**/package.json 2>/dev/null ||
    echo ""
}

get_deps() {
  pkg="$1"
  for dep in $(get_pkg_info "$pkg" |
    jq -r '(.dependencies // {}) + (.devDependencies // {}) + (.peerDependencies // {}) | keys | .[]'); do
    echo "$dep"
  done
}

get_my_deps() {
  username="$1"
  pkg="$2"
  collected="$3"
  if [[ -z "$collected" ]]; then
    collected=("$pkg")
  fi
  for dep in $(get_deps "$pkg"); do
    maintainers=''
    if [ "$ALLENE_PACMAN_CLI" == "yarn" ]; then
      maintainers=$(get_pkg_info "$dep" |
        jq -r '.maintainers[].name')
    else
      maintainers=$(get_pkg_info "$dep" |
        jq -r '.maintainers[] | capture("^(?<name>([\\w\\-]+))\\ <(?<email>(.*))>") | .name')
    fi
    if echo "$maintainers" | rg -q "^$username\$"; then
      if ! contains_element "$dep" "${collected[@]}"; then
        echo "$dep"
        collected+=("$dep")
        get_my_deps "$username" "$dep" "${collected[@]}"
      fi
    fi
  done
}

detect_peer_dependencies() {
  if [ -e "$PEER_DEPENDENCIES_BY_DEPENDENT_F" ]; then
    rm "$PEER_DEPENDENCIES_BY_DEPENDENT_F"
  fi
  if [ -e "$PEER_DEPENDENTS_BY_DEPENDENCY_F" ]; then
    rm "$PEER_DEPENDENTS_BY_DEPENDENCY_F"
  fi

  for caret_versioned_pkg in $(jq -r '.dependencies | to_entries | map("\(.key)@\(.value)") | .[]' package.json); do
    pkg=${caret_versioned_pkg//\^/''}
    get_pkg_info "$pkg" | jq 'select(.peerDependencies) | {(.name): .peerDependencies | keys}' \
      >>"$PEER_DEPENDENTS_BY_DEPENDENCY_F" || break
  done

  if [ -e "$PEER_DEPENDENTS_BY_DEPENDENCY_F" ]; then
    jq -s 'reduce .[] as $item({}; . * $item) | to_entries | map(select(.value | length > 0)) | map(.key as $mykey | reduce .value[] as $myvalue ({}; . * {($myvalue): [$mykey]})) | map(to_entries) | reduce .[] as $item ([]; . + $item) | reduce .[] as $item ({}; .[$item["key"]] += $item["value"])' \
      "$PEER_DEPENDENTS_BY_DEPENDENCY_F" >"$PEER_DEPENDENCIES_BY_DEPENDENT_F"
  else
      echo '{}' >"$PEER_DEPENDENCIES_BY_DEPENDENT_F"
  fi

  rm "$PEER_DEPENDENTS_BY_DEPENDENCY_F"
}

get_pkg_batches() {
  reqs_by_dep="$1"
  passed="$2"
  if [ -z "$passed" ]; then
    passed='[]'
  fi
  tranches="$3"
  if [ -z "$tranches" ]; then
    tranches='[]'
  fi
  reqs_by_dep_length=$(echo "$reqs_by_dep" | jq 'length')
  tranches=$(echo "$reqs_by_dep" | jq --argjson tranches "$tranches" --argjson passed "$passed" \
    '$tranches + [
        map(
          to_entries |
          map(select((.value - $passed | length) == 0))
        ) |
        flatten |
        map(.key) - $passed
      ]')
  passed=$(echo "$reqs_by_dep" |
    jq --argjson passed "$passed" \
      'map(
      to_entries |
      map(select((.value - $passed | length) == 0))
    ) |
    flatten |
    map(.key) + $passed |
    unique')
  passed_length=$(echo "$passed" | jq 'length')
  if [[ "$passed_length" -lt "$reqs_by_dep_length" ]]; then
    get_pkg_batches "$reqs_by_dep" "$passed" "$tranches"
  else
    echo "$tranches"
  fi
}

# Hide shellcheck complaint:
# shellcheck source=/dev/null
source "$HOMEBREW_LIBRARY/Homebrew/utils/lock.sh"

if [[ -n "$HOMEBREW_OSX" ]]
then
  if [[ "$HOMEBREW_PROCESSOR" = "Intel" ]]
  then
    ruby_URL="https://github.com/xu-cheng/homebrew-portable/releases/download/20160512/portable-ruby-2.0.0-p648.i386-darwin9.tar.gz"
    ruby_SHA="035ccdc2c073172148c5ffe3e7004011862b400c6aa3a2831c1cec46a0876de5"
  else
    ruby_URL=""
    ruby_SHA=""
  fi
else
  ruby_URL=""
  ruby_SHA=""
fi

cleanup-old() {
  # Vendor tools will be installed to Library/Homebrew/vendor/<name>/<version>
  # with a Library/Homebrew/vendor/<name>/opt symlink to point to current version.
  # This enables us to push updates in the future by simply update the symlink.
  for version in "$HOMEBREW_LIBRARY/Homebrew/vendor/$VENDOR_NAME"/*
  do
    [[ -L "$version" && "$(basename "$version")" = "opt" ]] && continue # skip opt symlink
    rm -rf "$version"
  done
}

install() {
  local curl_args
  local tar_args
  local sha

  if [[ -n "$HOMEBREW_VERBOSE" ]]
  then
    curl_args="-fLA"
    tar_args="xvzf"
  elif [[ -z "$HOMEBREW_QUIET" ]]
  then
    curl_args="-#fLA"
    tar_args="xzf"
  else
    curl_args="-sfLA"
    tar_args="xzf"
  fi

  VENDOR_FILE="$(/usr/bin/mktemp "/tmp/homebrew-$VENDOR_NAME.XXXXXX")"
  trap '{ rm -f "$VENDOR_FILE"; }' EXIT

  [[ -z "$HOMEBREW_QUIET" ]] && echo "==> Downloading $VENDOR_URL"
  "$HOMEBREW_CURL" "$curl_args" "$HOMEBREW_USER_AGENT_CURL" -o "$VENDOR_FILE" "$VENDOR_URL"

  if [[ -n "$(which shasum)" ]]
  then
    sha="$(shasum -a 256 "$VENDOR_FILE" | cut -d' ' -f1)"
  elif [[ -n "$(which sha256sum)" ]]
  then
    sha="$(sha256sum "$VENDOR_FILE" | cut -d' ' -f1)"
  else
    odie "Cannot verify the checksum ('shasum' or 'sha256sum' not found)!"
  fi

  if [[ "$sha" != "$VENDOR_SHA" ]]
  then
    odie <<EOS
Checksum mismatch.
Expected: $VENDOR_SHA
Actual: $sha
EOS
  fi

  chdir "$HOMEBREW_LIBRARY/Homebrew/vendor/$VENDOR_NAME"
  [[ -z "$HOMEBREW_QUIET" ]] && echo "==> Install $(basename "$VENDOR_URL")"
  trap '' SIGINT
  tar "$tar_args" "$VENDOR_FILE"
  rm -f "$VENDOR_FILE"
  trap - SIGINT
}

homebrew-install-vendor() {
  local option
  local url_var
  local sha_var

  for option in "$@"
  do
    case "$option" in
      -\?|-h|--help|--usage) brew help install-vendor; exit $? ;;
      --verbose) HOMEBREW_VERBOSE=1 ;;
      --quiet) HOMEBREW_QUIET=1 ;;
      --debug) HOMEBREW_DEBUG=1 ;;
      --*) ;;
      -*)
        [[ "$option" = *v* ]] && HOMEBREW_VERBOSE=1;
        [[ "$option" = *q* ]] && HOMEBREW_QUIET=1;
        [[ "$option" = *d* ]] && HOMEBREW_DEBUG=1;
        ;;
      *)
        [[ -n "$VENDOR_NAME" ]] && odie "This command does not take multiple vendor targets"
        VENDOR_NAME="$option"
        ;;
    esac
  done

  [[ -z "$VENDOR_NAME" ]] && odie "This command requires one vendor target."
  [[ -n "$HOMEBREW_DEBUG" ]] && set -x

  url_var="${VENDOR_NAME}_URL"
  sha_var="${VENDOR_NAME}_SHA"
  VENDOR_URL="${!url_var}"
  VENDOR_SHA="${!sha_var}"

  if [[ -z "$VENDOR_URL" || -z "$VENDOR_SHA" ]]
  then
    odie "Cannot find a vendored version of $VENDOR_NAME."
  fi

  lock "install-vendor-$VENDOR_NAME"
  cleanup-old
  install
}

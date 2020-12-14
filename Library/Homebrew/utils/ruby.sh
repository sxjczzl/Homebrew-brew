# shellcheck disable=SC2039

export HOMEBREW_REQUIRED_RUBY_VERSION=2.6.3

test_ruby () {
  if [[ ! -x $1 ]]
  then
    return 1
  fi

  "$1" --enable-frozen-string-literal --disable=gems,did_you_mean,rubyopt \
    "$HOMEBREW_LIBRARY/Homebrew/utils/ruby_check_version_script.rb" \
    "$HOMEBREW_REQUIRED_RUBY_VERSION" 2>/dev/null
}

find_usable_ruby () {
  if [[ -n "$HOMEBREW_MACOS" ]]
  then
    HOMEBREW_RUBY_PATH="/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
  else
    local ruby_exec
    local IFS=$'\n' # Do word splitting on new lines only
    HOMEBREW_RUBY_PATH=
    for ruby_exec in $(which -a ruby) $(PATH=$HOMEBREW_PATH which -a ruby)
    do
      if test_ruby "$ruby_exec"
      then
        HOMEBREW_RUBY_PATH=$ruby_exec
        break
      fi
    done
  fi
}

need_vendored_ruby () {
  if [[ -n "$HOMEBREW_FORCE_VENDOR_RUBY" ]]
  then
    return 0
  elif [[ -n "$HOMEBREW_MACOS_SYSTEM_RUBY_NEW_ENOUGH" ]]
  then
    return 1
  elif [[ -z "$HOMEBREW_MACOS" ]] && test_ruby "$HOMEBREW_RUBY_PATH"
  then
    return 1
  else
    return 0
  fi
}

setup-ruby-path() {
  local vendor_dir
  local vendor_ruby_root
  local vendor_ruby_path
  local vendor_ruby_terminfo
  local vendor_ruby_latest_version
  local vendor_ruby_current_version
  # When bumping check if HOMEBREW_MACOS_SYSTEM_RUBY_NEW_ENOUGH (in brew.sh)
  # also needs to be changed.
  local upgrade_fail
  local install_fail

  upgrade_fail="Failed to upgrade Homebrew Portable Ruby!${HOMEBREW_FORCE_VENDOR_RUBY:+"
HOMEBREW_FORCE_VENDOR_RUBY variable is currently set.
It prevents Homebrew from using other Ruby that might be available on your system.
If Ruby $HOMEBREW_REQUIRED_RUBY_VERSION is available on your system, you may safely unset HOMEBREW_FORCE_VENDOR_RUBY."}"

  if [[ -n $HOMEBREW_MACOS ]]
  then
    install_fail="Failed to install Homebrew Portable Ruby (and your system version is too old)!"
  else
    install_fail="Failed to install Homebrew Portable Ruby and cannot find another Ruby $HOMEBREW_REQUIRED_RUBY_VERSION!
If there's no Homebrew Portable Ruby available for your processor:
- install Ruby $HOMEBREW_REQUIRED_RUBY_VERSION with your system package manager (or rbenv/ruby-build)
- make it first in your PATH
- try again
"
  fi

  vendor_dir="$HOMEBREW_LIBRARY/Homebrew/vendor"
  vendor_ruby_root="$vendor_dir/portable-ruby/current"
  vendor_ruby_path="$vendor_ruby_root/bin/ruby"
  vendor_ruby_terminfo="$vendor_ruby_root/share/terminfo"
  vendor_ruby_latest_version=$(<"$vendor_dir/portable-ruby-version")
  vendor_ruby_current_version=$(readlink "$vendor_ruby_root")

  unset HOMEBREW_RUBY_PATH

  # Prefer portable Ruby if/when it's available
  if [[ -x "$vendor_ruby_path" ]]
  then
    HOMEBREW_RUBY_PATH=$vendor_ruby_path
    TERMINFO_DIRS=$vendor_ruby_terminfo
    if [[ $vendor_ruby_current_version != "$vendor_ruby_latest_version" ]] && ! brew vendor-install ruby
    then
      onoe "$upgrade_fail"
      unset TERMINFO_DIRS
      find_usable_ruby
      need_vendored_ruby && exit 1
    fi
  else
    find_usable_ruby
    if need_vendored_ruby
    then
      brew vendor-install ruby || odie "$install_fail"
      HOMEBREW_RUBY_PATH=$vendor_ruby_path
      TERMINFO_DIRS=$vendor_ruby_terminfo
    fi
  fi

  export HOMEBREW_RUBY_PATH
  [[ -n "$HOMEBREW_LINUX" && -n "$TERMINFO_DIRS" ]] && export TERMINFO_DIRS
}

setup-ruby-path() {
  if [[ -z "$HOMEBREW_DEVELOPER" ]]
  then
    unset HOMEBREW_RUBY_PATH
  fi

  if [[ -z "$HOMEBREW_RUBY_PATH" && "$HOMEBREW_COMMAND" != "install-vendor" ]]
  then
    HOMEBREW_VENDOR_RUBY_PATH="$HOMEBREW_LIBRARY/Homebrew/vendor/ruby/opt/bin/ruby"
    if [[ -x "$HOMEBREW_VENDOR_RUBY_PATH" ]]
    then
      HOMEBREW_RUBY_PATH="$HOMEBREW_VENDOR_RUBY_PATH"
    else
      if [[ -n "$HOMEBREW_OSX" ]]
      then
        HOMEBREW_RUBY_PATH="/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
      else
        HOMEBREW_RUBY_PATH="$(which ruby)"
      fi

      if [[ -z "$HOMEBREW_RUBY_PATH" || "$("$HOMEBREW_RUBY_PATH" -e "puts RUBY_VERSION.split('.').first")" != "2" ]]
      then
        brew install-vendor ruby --quiet
        if [[ ! -x "$HOMEBREW_VENDOR_RUBY_PATH" ]]
        then
          odie "Failed to install vendor Ruby."
        fi
        HOMEBREW_RUBY_PATH="$HOMEBREW_VENDOR_RUBY_PATH"
      fi
    fi
  fi

  export HOMEBREW_RUBY_PATH
}

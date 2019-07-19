#:  * `shellenv`
#:
#:  Prints export statements - run them in a shell and this installation of Homebrew will be included into your `PATH`, `MANPATH` and `INFOPATH`.
#:
#:  `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR` and `HOMEBREW_REPOSITORY` are also exported to save multiple queries of those variables.
#:
#:  Consider adding evaluating the output in your dotfiles (e.g. `~/.profile`) with `eval $(brew shellenv)`

homebrew-shellenv() {
  case "$SHELL" in
    */fish)
      echo "builtin set -gx HOMEBREW_PREFIX \"$HOMEBREW_PREFIX\";"
      echo "builtin set -gx HOMEBREW_CELLAR \"$HOMEBREW_CELLAR\";"
      echo "builtin set -gx HOMEBREW_REPOSITORY \"$HOMEBREW_REPOSITORY\";"
      echo "builtin set -g fish_user_paths \"$HOMEBREW_PREFIX/bin\" \"$HOMEBREW_PREFIX/sbin\" \$fish_user_paths;"
      echo "builtin set -q MANPATH; or set MANPATH ''; set -gx MANPATH \"$HOMEBREW_PREFIX/share/man\" \$MANPATH;"
      echo "builtin set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH \"$HOMEBREW_PREFIX/share/info\" \$INFOPATH;"
      ;;
    */csh|*/tcsh)
      echo "setenv HOMEBREW_PREFIX $HOMEBREW_PREFIX;"
      echo "setenv HOMEBREW_CELLAR $HOMEBREW_CELLAR;"
      echo "setenv HOMEBREW_REPOSITORY $HOMEBREW_REPOSITORY;"
      echo "setenv PATH $HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH;"
      echo "setenv MANPATH $HOMEBREW_PREFIX/share/man:\$MANPATH;"
      echo "setenv INFOPATH $HOMEBREW_PREFIX/share/info:\$INFOPATH;"
      ;;
    *)
      echo "builtin export HOMEBREW_PREFIX=\"$HOMEBREW_PREFIX\""
      echo "builtin export HOMEBREW_CELLAR=\"$HOMEBREW_CELLAR\""
      echo "builtin export HOMEBREW_REPOSITORY=\"$HOMEBREW_REPOSITORY\""
      echo "builtin export PATH=\"$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH\""
      echo "builtin export MANPATH=\"$HOMEBREW_PREFIX/share/man:\$MANPATH\""
      echo "builtin export INFOPATH=\"$HOMEBREW_PREFIX/share/info:\$INFOPATH\""
      ;;
  esac
}

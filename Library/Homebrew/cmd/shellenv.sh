#:  * `shellenv`
#:
#:  Print export statements. When run in a shell, this installation of Homebrew will be added to your `PATH`, `MANPATH`, and `INFOPATH`.
#:
#:  The variables `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR` and `HOMEBREW_REPOSITORY` are also exported to avoid querying them multiple times.
#:  Consider adding evaluation of this command's output to your dotfiles (e.g. `~/.profile`, `~/.bash_profile`, or `~/.zprofile`) with: `eval $(brew shellenv)`
#:  or for a xonsh shell with: `execx($(/home/linuxbrew/.linuxbrew/bin/brew shellenv))` (or `execx($(~/.linuxbrew/bin/brew shellenv))` depending on the install path)

homebrew-shellenv() {
  case "$(/bin/ps -p $PPID -c -o comm=)" in
    fish|-fish)
      echo "set -gx HOMEBREW_PREFIX \"$HOMEBREW_PREFIX\";"
      echo "set -gx HOMEBREW_CELLAR \"$HOMEBREW_CELLAR\";"
      echo "set -gx HOMEBREW_REPOSITORY \"$HOMEBREW_REPOSITORY\";"
      echo "set -q PATH; or set PATH ''; set -gx PATH \"$HOMEBREW_PREFIX/bin\" \"$HOMEBREW_PREFIX/sbin\" \$PATH;"
      echo "set -q MANPATH; or set MANPATH ''; set -gx MANPATH \"$HOMEBREW_PREFIX/share/man\" \$MANPATH;"
      echo "set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH \"$HOMEBREW_PREFIX/share/info\" \$INFOPATH;"
      ;;
    csh|-csh|tcsh|-tcsh)
      echo "setenv HOMEBREW_PREFIX $HOMEBREW_PREFIX;"
      echo "setenv HOMEBREW_CELLAR $HOMEBREW_CELLAR;"
      echo "setenv HOMEBREW_REPOSITORY $HOMEBREW_REPOSITORY;"
      echo "setenv PATH $HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH;"
      echo "setenv MANPATH $HOMEBREW_PREFIX/share/man\`[ \${?MANPATH} == 1 ] && echo \":\${MANPATH}\"\`:;"
      echo "setenv INFOPATH $HOMEBREW_PREFIX/share/info\`[ \${?INFOPATH} == 1 ] && echo \":\${INFOPATH}\"\`;"
      ;;
    xonsh|-xonsh)
      echo "\$HOMEBREW_PREFIX='$HOMEBREW_PREFIX';"
      echo "\$HOMEBREW_CELLAR='$HOMEBREW_CELLAR';"
      echo "\$HOMEBREW_REPOSITORY='$HOMEBREW_REPOSITORY';"
      echo "\$PATH = \$PATH if 'PATH' in \${...} else '';"
      echo "\$PATH.add('$HOMEBREW_PREFIX/sbin', front=True, replace=True);"
      echo "\$PATH.add('$HOMEBREW_PREFIX/bin', front=True, replace=True);"
      echo "\$MANPATH = \$MANPATH if 'MANPATH' in \${...} else '';"
      echo "\$MANPATH.add('$HOMEBREW_PREFIX/share/man', front=True, replace=True);"
      echo "\$INFOPATH = \$INFOPATH if 'INFOPATH' in \${...} else '';"
      echo "\$INFOPATH.add('$HOMEBREW_PREFIX/share/info', front=True, replace=True);"
      ;;
    *)
      echo "export HOMEBREW_PREFIX=\"$HOMEBREW_PREFIX\";"
      echo "export HOMEBREW_CELLAR=\"$HOMEBREW_CELLAR\";"
      echo "export HOMEBREW_REPOSITORY=\"$HOMEBREW_REPOSITORY\";"
      echo "export PATH=\"$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin\${PATH+:\$PATH}\";"
      echo "export MANPATH=\"$HOMEBREW_PREFIX/share/man\${MANPATH+:\$MANPATH}:\";"
      echo "export INFOPATH=\"$HOMEBREW_PREFIX/share/info:\${INFOPATH:-}\";"
      ;;
  esac
}

#:  * `formulae`
#:
#:  List all locally installable formulae including short names.
#:

smart-sed() {
  if [[ -n $(/usr/bin/sed -E 's:1::' <<< 1 2>&1) ]]
  then
    for arg in "$@"
    do
      if [[ "$arg" =~ ^-.*E ]]
      then
        shift
        set -- "${arg//E/r}" "$@"
      fi
    done
  fi
  /usr/bin/sed "$@"
}

homebrew-formulae() {
  local formulae
  formulae="$( \
    find "$HOMEBREW_REPOSITORY/Library/Taps" \
         -type d \( \
           -name Casks -o \
           -name cmd -o \
           -name .github -o \
           -name lib -o \
           -name spec -o \
           -name vendor \
          \) \
         -prune -false -o -name '*\.rb' | \
    smart-sed \
        -E -e 's/\.rb//g' \
           -e 's_.*/Taps/(.*)/(home|linux)brew-_\1/_' \
           -e 's|/Formula/|/|' \
  )"
  local shortnames
  shortnames="$(echo "$formulae" | cut -d "/" -f 3)"
  echo -e "$formulae \n $shortnames" | \
    grep -v '^homebrew/core' | \
    sort -uf
}

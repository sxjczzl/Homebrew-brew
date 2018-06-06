# How to Revendor a Dependency

At the time of writing, Homebrew vendors several dependencies within the
[Library/Homebrew/vendor](https://github.com/Homebrew/brew/tree/master/Library/Homebrew/vendor)
subdirectory.

This page serves to document the process for revendoring these dependencies, i.e. replacing the
vendored copy with a more recent version.

## Copying the files

Here's an example for the imaginary "foobar" vendored dependency:

Each directory in `vendor/` contains the **contents** of the `lib/` directory for the corresponding
dependency. Thus, `require`ing a vendored dependency looks like this:

```ruby
require "vendor/foobar/file"
```

The copying process is almost as simple as removing the old files, and copying the new files into
place:

```bash
git rm -rf --cached /path/to/brew/Library/Homebrew/vendor/foobar
rm -rf /path/to/brew/Library/Homebrew/vendor/foobar/
cp -R /path/to/foobar/lib/ /path/to/brew/Library/Homebrew/vendor/foobar/
```

Note that the new vendored directory will be a copy of `foobar/lib`, not of `foobar` itself.

## Updating the README

Once the files are updated, make sure that the
[README](https://github.com/Homebrew/brew/blob/master/Library/Homebrew/vendor/README.md) within
`vendor/` is still accurate.

This includes:

1. Making sure the URL listed for the dependency is still correct
2. Updating the version number listed next to the URL
3. Updating the quoted license text for the dependency, if necessary

That's it!

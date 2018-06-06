# How to Revendor a Dependency

At the time of writing, Homebrew vendors several dependencies within the
[Library/Homebrew/vendor](https://github.com/Homebrew/brew/tree/master/Library/Homebrew/vendor)
subdirectory.

This page serves to document the process for revendoring these dependencies.

## Copying the files

Each directory in `vendor/` contains the **contents** of the `lib/` directory for the corresponding
dependency. Thus, `require`ing a vendored dependency looks like this:

```ruby
require "vendor/library/file"
```

Thus, the copying process is as simple as removing the old files, and copying the new files into
place.

Here's an example for the imaginary "foobar" vendored dependency:

```bash
rm -rf /path/to/brew/Library/Homebrew/vendor/foobar/*
cp -R /path/to/foobar/lib/* /path/to/brew/Library/Homebrew/vendor/foobar/
```

Note that we copy the **contents** of `foobar/lib/` to the vendored directory, not `lib/` itself.

Note, also, that the `rm` step is not necessary if you know that the updated version does not
contain fewer files than the current version. Running it will never hurt, though, so there's no
point in skipping it.

## Updating the README

Once the actual files of the vendored dependency are updated, you should make sure that the
[README](https://github.com/Homebrew/brew/blob/master/Library/Homebrew/vendor/README.md) within
`vendor/` is still accurate.

This includes:

1. Making sure the URL listed for the dependency is still correct
2. Updating the version listed next to the URL
3. Updating the quoted license text for the dependency, if necessary

That's it!

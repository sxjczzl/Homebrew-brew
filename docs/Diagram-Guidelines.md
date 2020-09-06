# Diagram Guidelines

## Preferred file format

For complex diagrams, use the `.drawio.svg` format.

Files with the `.drawio.svg` extension are SVG files with embedded [draw.io](https://www.diagrams.net/) source code. Using that format lends itself to a developer-friendly workflow: it is valid SVG, plays well with `git diff` and can be edited in lock-step using various online and offline flavours of draw.io. If you use VS Code, you can use an [extension](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) for draw.io integration.

Files in the `.drawio.svg` format can be processed offline.

## Embedding a diagram into Markdown

To embed a `.drawio.svg` file into Markdown, use the same syntax as for any image. Example: `![My diagram](my-diagram.drawio.svg)`

Mind that GitHub doesn’t allow styling in Markdown documents. Where styling is allowed (e.g. in the exported brew.sh version of the documentation), always set a background colour of `white` for the diagram. That’s the colour draw.io assumes, and keeps the diagram easy to read in dark mode without further customization. You can use the CSS selector `img[src$=".drawio.svg"]` for styling.

## Example

Example for an SVG image embedded into Markdown:

```md
![Example diagram: Managing Pull Requests](assets/img/docs/managing-pull-requests.drawio.svg)
```

Result:

![Example diagram: Managing Pull Requests](assets/img/docs/managing-pull-requests.drawio.svg)

Example for styling (where allowed):

```css
img[src$=".drawio.svg"] {
  background-color: white;
  margin-bottom: 20px;
  padding: 5%;
  width: 90%;
}

@media (prefers-color-scheme: dark) {
  img[src$=".drawio.svg"] {
    filter: invert(85%);
    -webkit-filter: invert(85%);
  }
}
```

## The Git diff driver

Setting up a Git diff driver for `.drawio.svg` files is optional. The diff driver is useful to have though: it makes `git diff` ignore the SVG part and look at the original source only.

### How a diff driver helps

Without a diff driver:

```diff
--- a/managing-pull-requests.drawio.svg
+++ b/managing-pull-requests.drawio.svg
@@ -1,4 +1,4 @@
-<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="759px" height="936px" viewBox="-0.5 -0.5 759 936" content="&lt;mxfile host=&quot;&quot; modified=&quot;2020-07-16T21:15:00.400Z&quot; agent=&quot;5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.46.1 Chrome/78.0.3904.130 Electron/7.3.1 Safari/537.36&quot; etag=&quot;pmHBLrtnrX4nNGyRVqOD&quot; version=&quot;13.1.3&quot;&gt;&lt;diagram id=&quot;6hGFLwfOUW9BJ-s0fimq&quot; name=&quot;Page-1&quot;&gt;7Vzbkps4EP0aP3oKxM1+nOsmVcnWVGUr2TylsJFtdjFyhJix8/UrgWSQBLbHCHuozcsMSKIR6u7TRy3JI+d+vf0Dh5vVZxTBZASsaDtyHkYA2Baw6T9WsitLJrZXFixxHPFGVcGX+BcUT/LSPI5gJjUkCCUk3siFc5SmcE
[…] (184 lines omitted)
```

With the diff driver:

```diff
--- a/managing-pull-requests.drawio.svg
+++ b/managing-pull-requests.drawio.svg
@@ -188,5 +188,8 @@
     <mxCell id="54" parent="1" style="verticalLabelPosition=bottom;verticalAlign=top;html=1;shape=trapezoid;perimeter=trapezoidPerimeter;whiteSpace=wrap;size=0.23;arcSize=10;flipV=1;" vertex="1" value="Push the button">
       <mxGeometry x="560" y="550" width="100" height="60" as="geometry"/>
     </mxCell>
+    <mxCell id="70" parent="1" style="" vertex="1" value="Cheers!">
+      <mxGeometry x="92" y="900" width="120" height="60" as="geometry"/>
+    </mxCell>
   </root>
 </mxGraphModel>
```

### Installing the diff driver on macOS

To add the `drawio-mxfile-svg` diff driver to your `~/.gitconfig` file, run the following command line from your terminal:

```bash
git config --global diff.drawio-mxfile-svg.textconv "f() { post_processor=\"\${HOMEBREW_REPOSITORY:-\$(brew --repository)}/docs/contrib/git-textconv/git-textconv-drawio-mxfile.xml\"; if [ -e \"\${post_processor}\" ]; then sed -e '/^<"'!'"DOCTYPE/d' \"\$@\" | xmllint --xpath 'string(/*/@content)' - | xmllint --xpath '/mxfile/diagram/text()' - | base64 --decode | bash -c 'cat <(/usr/bin/xxd -r -p <<< \"1f 8b 08 08 d1 ee 75 58 00 03 63 6f 6e 74 65 6e 74 2e 62 61 73 65 36 34 00\") -' | gunzip 2>/dev/null | ruby -rcgi -pe '\$_ = CGI::unescape(\$_)' | xsltproc \"\${post_processor}\" -; else cat \"\$@\"; fi; }; f"
```

### Installing the diff driver on Linux

The `drawio-mxfile-svg` diff driver hasn’t been tested yet on Linux.

The diff driver depends on the command-line utilities `base64`, `bash`, `gunzip`, `ruby`, `sed`, `xmllint` and `xsltproc`. Some of those utilities may not be preinstalled on all Linux distributions.

### How the diff driver is implemented

Homebrew’s `.gitattributes` file has a `textconv` entry, which associates the diff driver with `.drawio.svg` files.
That should be enough information to use the diff driver.
Just in case the diff driver ever needs debugging, here’s a rundown on its implementation:

1. Call a shell function `f`. This allows the `textconv` logic to accept not only a single command but a sequence of commands.
1. Accept a path to a *.drawio.svg file, controlled by Git.
  (The diff driver will not modify that file nor any other file.)
1. Remove the XML document declaration so `xmllint` can read the file.
1. Extract the embedded draw.io source code from the SVG file. This is a two-stage process: the first `xmllint` command extracts serialized XML from the `content` attribute, the second one selects the `/mxfile/diagram` part from the payload.
1. Base64-decode the result to a headerless zipped stream.
1. Prepend a ZIP header so `gunzip` can process the stream.
1. Unzip the result.
1. Unescape URL-encoded bytes.
1. Post-process the source code to rearrange XML attributes into a defined order.
1. Print the result to standard output, ready to be read back by Git.

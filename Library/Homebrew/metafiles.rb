# frozen_string_literal: true

module Metafiles
  # https://github.com/github/markup#markups
  EXTENSIONS = Set.new(%w[
                         .adoc .asc .asciidoc .creole .html .markdown .md .mdown .mediawiki .mkdn
                         .org .pod .rdoc .rst .rtf .textile .txt .wiki
                       ]).freeze
  BASENAMES = Set.new(%w[
                        about authors changelog changes copying copyright history license licence
                        news notes notice readme todo
                      ]).freeze

  module_function

  def license?(file)
    file = file.upcase
    ext = File.extname(file)
    file = File.basename(file, ext)
    file.gsub!("LICENCE", "LICENSE")
    file == "LICENSE" || file.start_with?("LICENSE-")
  end

  def list?(file)
    return false if %w[.DS_Store INSTALL_RECEIPT.json].include?(file)

    !copy?(file)
  end

  def copy?(file)
    return true if license?(file)

    file = file.downcase
    ext  = File.extname(file)
    file = File.basename(file, ext) if EXTENSIONS.include?(ext)
    BASENAMES.include?(file)
  end
end

#:  * `leaves`:
#:    Show installed formulae that are not dependencies of another installed formula.

require "formula"
require "tab"
require "set"

module Homebrew
  module_function

  def leaves
    installed = Formula.installed.sort
    deps_of_installed = Set.new

    installed.each do |f|
      deps = []

      f.deps.each do |dep|
        if dep.optional? || dep.recommended?
          deps << dep.to_formula.full_name if f.build.with?(dep)
        else
          deps << dep.to_formula.full_name
        end
      end

      reqs = []

      f.requirements.to_a.each do |req|
        dep = req.to_dependency
        next if dep.nil?
        if req.optional? || req.recommended?
          reqs << dep.to_formula.full_name if f.build.with?(req)
        else
          reqs << dep.to_formula.full_name
        end
      end

      deps_of_installed.merge(deps + reqs)
    end

    installed.each do |f|
      puts f.full_name unless deps_of_installed.include? f.full_name
    end
  end
end

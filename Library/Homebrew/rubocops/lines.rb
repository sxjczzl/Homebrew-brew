# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for various miscellaneous Homebrew coding styles.
      #
      # @api private
      class Lines < FormulaCop
        def on_formula_depends_on(node)
          [:automake, :ant, :autoconf, :emacs, :expat, :libtool, :mysql, :perl,
           :postgresql, :python, :python3, :rbenv, :ruby].each do |dependency|
            next unless depends_on_matches?(node, dependency)

            problem ":#{dependency} is deprecated. Usage should be \"#{dependency}\"."
          end

          { apr: "apr-util", fortran: "gcc", gpg: "gnupg", hg: "mercurial",
            mpi: "open-mpi", python2: "python" }.each do |requirement, dependency|
            next unless depends_on_matches?(node, requirement)

            problem ":#{requirement} is deprecated. Usage should be \"#{dependency}\"."
          end

          problem ":tex is deprecated." if depends_on_matches?(node, :tex)
        end
      end

      # This cop makes sure that a space is used for class inheritance.
      #
      # @api private
      class ClassInheritance < FormulaCop
        def on_formula_class(class_node)
          begin_pos = start_column(class_node.parent_class)
          end_pos = end_column(class_node.identifier)
          return unless begin_pos-end_pos != 3

          problem "Use a space in class inheritance: " \
                  "class #{@formula_name.capitalize} < #{class_name(class_node.parent_class)}"
        end
      end

      # This cop makes sure that template comments are removed.
      #
      # @api private
      class Comments < FormulaCop
        TEMPLATE_COMMENTS = [
          "# PLEASE REMOVE",
          "# Documentation:",
          "# if this fails, try separate make/make install steps",
          "# The URL of the archive",
          "## Naming --",
          "# if your formula fails when building in parallel",
          "# Remove unrecognized options if warned by configure",
          '# system "cmake',
        ].freeze

        def on_formula_source(processed_source)
          processed_source.comments.each do |comment|
            TEMPLATE_COMMENTS.each do |template_comment|
              next unless comment.text.include?(template_comment)

              offending_node(comment)
              problem "Please remove default template comments"
              break
            end

            if comment.text =~ /#\s*depends_on\s+(.+)\s*$/
              # Commented-out depends_on
              offending_node(comment)
              problem "Commented-out dependency #{Regexp.last_match(1)}"
            elsif core_tap? && comment.text =~ /#\s*(cite(?=\s*\w+:)|doi(?=\s*['"])|tag(?=\s*['"]))/
              # Citation and tag comments from third-party taps

              offending_node(comment)
              problem "Formulae in homebrew/core should not use `#{Regexp.last_match(1)}` comments"
            end
          end
        end
      end

      # This cop makes sure that idiomatic `assert_*` statements are used.
      #
      # @api private
      class AssertStatements < FormulaCop
        def on_formula_send(send_node)
          return if send_node.method_name != :assert

          if method_called_ever?(send_node, :include?) && !method_called_ever?(send_node, :!)
            problem "Use `assert_match` instead of `assert ...include?`"
          end

          if method_called_ever?(send_node, :exist?) && !method_called_ever?(send_node, :!)
            problem "Use `assert_predicate <path_to_file>, :exist?` instead of `#{send_node.source}`"
          end

          if method_called_ever?(send_node, :exist?) && method_called_ever?(send_node, :!)
            problem "Use `refute_predicate <path_to_file>, :exist?` instead of `#{send_node.source}`"
          end

          return unless method_called_ever?(send_node, :executable?)
          return if method_called_ever?(send_node, :!)

          problem "Use `assert_predicate <path_to_file>, :executable?` instead of `#{send_node.source}`"
        end
      end

      # This cop makes sure that `option`s are used idiomatically.
      #
      # @api private
      class OptionDeclarations < FormulaCop
        def on_formula_def(def_node)
          return if def_node.method_name != :options

          offending_node(def_node)
          problem "Use new-style option definitions"
        end

        def on_formula_if(node)
          build_with_node = depends_on_build_with(node)
          return if build_with_node.nil?

          offending_node(build_with_node)
          problem "Use `:optional` or `:recommended` instead of `if #{build_with_node.source}`"
        end

        def on_formula_send(send_node)
          if send_node.method_name == :without? && instance_method_call?(send_node, :build)
            if core_tap?
              problem "Formulae in homebrew/core should not use `build.without?`."
            else
              if unless_modifier?(send_node.parent)
                correct = send_node.source.gsub("out?", "?")
                problem "Use if #{correct} instead of unless #{send_node.source}"
              end

              problem "Don't negate 'build.without?': use 'build.with?'" if expression_negated?(send_node)

              arg = parameters(send_node).first
              if (match = regex_match_group(arg, /^-?-?without-(.*)/))
                problem "Don't duplicate 'without': " \
                        "Use `build.without? \"#{match[1]}\"` to check for \"--without-#{match[1]}\""
              end
            end
          elsif send_node.method_name == :with? && instance_method_call?(send_node, :build)
            if core_tap?
              problem "Formulae in homebrew/core should not use `build.with?`."
            else
              if unless_modifier?(send_node.parent)
                correct = send_node.source.gsub("?", "out?")
                problem "Use if #{correct} instead of unless #{send_node.source}"
              end

              problem "Don't negate 'build.with?': use 'build.without?'" if expression_negated?(send_node)

              arg = parameters(send_node).first
              if (match = regex_match_group(arg, /^-?-?with-(.*)/))
                problem "Don't duplicate 'with': " \
                        "Use `build.with? \"#{match[1]}\"` to check for \"--with-#{match[1]}\""
              end
            end
          elsif send_node.method_name == :include? && instance_method_call?(send_node, :build)
            problem "`build.include?` is deprecated"
          end
        end

        private

        def unless_modifier?(node)
          return false unless node.if_type?

          node.modifier_form? && node.unless?
        end

        # Finds `depends_on "foo" if build.with?("bar")` or `depends_on "foo" if build.without?("bar")`
        def_node_matcher :depends_on_build_with, <<~EOS
          (if $(send (send nil? :build) {:with? :without?} str)
            (send nil? :depends_on str) nil?)
        EOS
      end

      # This cop makes sure that formulae depend on `open-mpi` instead of `mpich`.
      #
      # @api private
      class MpiCheck < FormulaCop
        extend AutoCorrector

        def on_formula_depends_on(node)
          # Enforce use of OpenMPI for MPI dependency in core
          return unless core_tap?
          return unless depends_on_matches?(node, "mpich")

          problem "Formulae in homebrew/core should use 'depends_on \"open-mpi\"' " \
                  "instead of '#{@offensive_node.source}'." do |corrector|
            corrector.replace(@offensive_node.source_range, "depends_on \"open-mpi\"")
          end
        end
      end

      # This cop makes sure that formulae do not depend on `pyoxidizer` at build-time
      # or run-time.
      #
      # @api private
      class PyoxidizerCheck < FormulaCop
        def on_depends_on(node)
          # Disallow use of PyOxidizer as a dependency in core
          return unless core_tap?
          return unless depends_on_matches?(node, "pyoxidizer")

          problem "Formulae in homebrew/core should not use '#{@offensive_node.source}'."
        end
      end

      # This cop makes sure that the safe versions of `popen_*` calls are used.
      #
      # @api private
      class SafePopenCommands < FormulaCop
        extend AutoCorrector

        UNSAFE_METHODS = [:popen_read, :popen_write].freeze

        def on_formula_class(_class_node)
          @test_methods = []
        end

        def on_formula_test(test_node)
          UNSAFE_METHODS.each do |unsafe_command|
            find_instance_method_call(test_node, "Utils", unsafe_command) do |method_call|
              @test_methods << method_call.source_range
            end
          end
        end

        def on_formula_send(send_node)
          method_name = send_node.method_name
          return unless UNSAFE_METHODS.include?(method_name)
          return unless instance_method_call?(send_node, "Utils")
          return if @test_methods.include?(send_node.source_range)

          problem "Use `Utils.safe_#{method_name}` instead of `Utils.#{method_name}`" do |corrector|
            corrector.replace(@offensive_node.loc.selector, "safe_#{@offensive_node.method_name}")
          end
        end
      end

      # This cop makes sure that environment variables are passed correctly to `popen_*` calls.
      #
      # @api private
      class ShellVariables < FormulaCop
        extend AutoCorrector

        POPEN_COMMANDS = [
          :popen,
          :popen_read,
          :safe_popen_read,
          :popen_write,
          :safe_popen_write,
        ].freeze

        def on_formula_send(send_node)
          command = send_node.method_name
          return unless POPEN_COMMANDS.include?(command)
          return unless instance_method_call?(send_node, "Utils")
          return unless (match = regex_match_group(parameters(send_node).first, /^([^"' ]+)=([^"' ]+)(?: (.*))?$/))

          good_args = "Utils.#{command}({ \"#{match[1]}\" => \"#{match[2]}\" }, \"#{match[3]}\")"

          problem "Use `#{good_args}` instead of `#{send_node.source}`" do |corrector|
            corrector.replace(@offensive_node.source_range,
                              "{ \"#{match[1]}\" => \"#{match[2]}\" }, \"#{match[3]}\"")
          end
        end
      end

      # This cop makes sure that `license` has the correct format.
      #
      # @api private
      class LicenseArrays < FormulaCop
        extend AutoCorrector

        def on_formula_license(license_node)
          license = parameters(license_node).first
          return unless license.array_type?

          offending_node(license_node)
          problem "Use `license any_of: #{license.source}` instead of `license #{license.source}`" do |corrector|
            corrector.replace(license_node.source_range, "license any_of: #{parameters(license_node).first.source}")
          end
        end
      end

      # This cop makes sure that nested `license` declarations are split onto multiple lines.
      #
      # @api private
      class Licenses < FormulaCop
        def on_formula_license(node)
          return if node.source.include?("\n")

          parameters(node).first.each_descendant(:hash).each do |license_hash|
            next if license_exception? license_hash

            offending_node(node)
            problem "Split nested license declarations onto multiple lines"
          end
        end

        def_node_matcher :license_exception?, <<~EOS
          (hash (pair (sym :with) str))
        EOS
      end

      # This cop makes sure that Python versions are consistent.
      #
      # @api private
      class PythonVersions < FormulaCop
        extend AutoCorrector

        def on_formula_class(_class_node)
          @python_versions = []
        end

        def on_formula_depends_on(depends_on_node)
          dep_name = string_content(parameters(depends_on_node).first)
          return unless dep_name.start_with?("python@")

          @python_versions << dep_name.split("@").last
        end

        def on_formula_class_end(class_node)
          return if @python_versions.empty?

          find_strings(class_node.body).each do |str|
            content = string_content(str)

            next unless (match = content.match(/^python(@)?(\d\.\d+)$/))
            next if @python_versions.include?(match[2])

            fix = if match[1]
              "python@#{@python_versions.first}"
            else
              "python#{@python_versions.first}"
            end

            offending_node(str)
            problem "References to `#{content}` should "\
                    "match the specified python dependency (`#{fix}`)" do |corrector|
              corrector.replace(str.source_range, "\"#{fix}\"")
            end
          end
        end
      end

      # This cop makes sure that OS conditionals are consistent.
      #
      # @api private
      class OSConditionals < FormulaCop
        extend AutoCorrector

        OS_METHODS = [[:on_macos, :mac?], [:on_linux, :linux?]].freeze

        def on_formula_install(node)
          enforce_if_os_usage(node)
        end

        def on_formula_post_install(node)
          enforce_if_os_usage(node)
        end

        def on_formula_service(node)
          enforce_if_os_usage(node)
        end

        def on_formula_test(node)
          enforce_if_os_usage(node)
        end

        def on_formula_send(send_node)
          # Don't restrict OS.mac? or OS.linux? usage in taps; they don't care
          # as much as we do about e.g. formulae.brew.sh generation, often use
          # platform-specific URLs and we don't want to add DSLs to support
          # that case.
          return unless core_tap?
          return unless (on_method_name, = OS_METHODS.find { |_, if_method| if_method == send_node.method_name })
          return unless instance_method_call?(send_node, "OS")

          no_on_os_method_names = [:install, :post_install].freeze
          no_on_os_block_names = [:service, :test].freeze

          valid = T.let(false, T::Boolean)
          send_node.each_ancestor do |ancestor|
            valid_method_names = case ancestor.type
            when :def
              no_on_os_method_names
            when :block
              no_on_os_block_names
            else
              next
            end
            next unless valid_method_names.include?(ancestor.method_name)

            valid = true
            break
          end
          return if valid

          offending_node(send_node)
          problem "Don't use 'if OS.#{send_node.method_name}', use '#{on_method_name} do' instead." do |corrector|
            if_node = send_node.parent
            next if if_node.type != :if

            # TODO: could fix corrector to handle this but punting for now.
            next if if_node.unless?

            corrector.replace(if_node.source_range, "#{on_method_name} do\n#{if_node.body.source}\nend")
          end
        end

        private

        def enforce_if_os_usage(node)
          OS_METHODS.each do |on_method_name, if_method_name|
            if_method_and_class = "if OS.#{if_method_name}"

            if node.block_type?
              next unless block_method_called_in_block?(node, on_method_name)

              problem "Don't use '#{on_method_name}' in '#{node.method_name} do', " \
                      "use '#{if_method_and_class}' instead." do |corrector|
                # TODO: could fix corrector to handle this but punting for now.
                next if offending_node.single_line?

                source_range = offending_node.send_node.source_range.join(offending_node.body.source_range.begin)
                corrector.replace(source_range, "#{if_method_and_class}\n")
              end
            else
              next unless method_called_ever?(node, on_method_name)

              problem "Don't use '#{on_method_name}' in 'def #{node.method_name}', " \
                      "use '#{if_method_and_class}' instead." do |corrector|
                block_node = offending_node.parent
                next if block_node.type != :block

                # TODO: could fix corrector to handle this but punting for now.
                next if block_node.single_line?

                source_range = offending_node.source_range.join(offending_node.parent.loc.begin)
                corrector.replace(source_range, if_method_and_class)
              end
            end
          end
        end
      end

      # This cop checks for other miscellaneous style violations.
      #
      # @api private
      class Miscellaneous < FormulaCop
        def on_formula_send(send_node)
          # FileUtils is included in Formula
          # encfs modifies a file with this name, so check for some leading characters
          if instance_method_call?(send_node, "FileUtils")
            problem "Don't need 'FileUtils.' before #{send_node.method_name}"
          end

          if instance_method_call?(send_node, "ARGV")
            offending_node(send_node.receiver)
            problem "Use build instead of ARGV to check options"
          end

          if send_node.method_name == :+ && instance_method_call?(send_node, :man) &&
             (match = regex_match_group(parameters(send_node).first, /^man[1-8]$/))

            problem "\"#{send_node.source}\" should be \"#{match[0]}\""
          end

          # Avoid hard-coding compilers
          if send_node.method_name == :system ||
             (send_node.method_name == :[]= && instance_method_call?(send_node, "ENV"))
            params = parameters(send_node)
            param_to_check = if send_node.method_name == :system
              params.first
            else
              params[1]
            end

            if (match = regex_match_group(param_to_check, %r{^(/usr/bin/)?(gcc|llvm-gcc|clang)(\s|$)}))
              problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{match[2]}\""
            elsif (match = regex_match_group(param_to_check, %r{^(/usr/bin/)?((g|llvm-g|clang)\+\+)(\s|$)}))
              problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{match[2]}\""
            end
          end

          if send_node.method_name == :system &&
             (match = regex_match_group(parameters(send_node).first, /^(env|export)(\s+)?/))
            problem "Use ENV instead of invoking '#{match[1]}' to modify the environment"
          end

          if send_node.method_name == :== && instance_method_call?(send_node, :version) &&
             parameters_passed?(send_node, "HEAD")
            problem "Use 'build.head?' instead of inspecting 'version'"
          end

          if send_node.method_name == :include? && instance_method_call?(send_node, "ARGV") &&
             parameters_passed?(send_node, "--HEAD")
            problem "Use \"if build.head?\" instead"
          end

          if send_node.method_name == :system && parameters_passed?(send_node, /^(otool|install_name_tool|lipo)/)
            problem "Use ruby-macho instead of calling #{@offensive_node.source}"
          end

          # Skip Kibana: npm cache edge (see formula for more details)
          if send_node.method_name == :system && !@formula_name.match?(/^kibana(@\d[\d.]*)?$/)
            first_param, second_param = parameters(send_node)
            if first_param&.str_type? && first_param.value == "npm" &&
               second_param&.str_type? && second_param.value == "install"
              offending_node(send_node)
              problem "Use Language::Node for npm install args" unless languageNodeModule?(send_node)
            end
          end

          if send_node.method_name == :universal? && instance_method_call?(send_node, :build) &&
             @formula_name != "wine"
            problem "macOS has been 64-bit only since 10.6 so build.universal? is deprecated."
          end

          if send_node.method_name == :universal_binary && instance_method_call?(send_node, "ENV") &&
             @formula_name != "wine"
            problem "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated."
          end

          if send_node.method_name == :runtime_cpu_detection && instance_method_call?(send_node, "ENV") &&
             !tap_style_exception?(:runtime_cpu_detection_allowlist)
            problem "Formulae should be verified as having support for runtime hardware detection before " \
                    "using ENV.runtime_cpu_detection."
          end

          if send_node.method_name == :[] && instance_method_call?(send_node, "ENV") && !modifier?(send_node.parent)
            param = parameters(send_node).first
            problem 'Don\'t use ENV["CI"] for Homebrew CI checks.' if param&.str_type? && param.value == "CI"
          end

          if send_node.method_name == :[] && instance_method_call?(send_node, "Dir") &&
             parameters(send_node).size == 1
            path = parameters(send_node).first
            if path.str_type? && (match = regex_match_group(path, /^[^*{},]+$/))
              problem "Dir([\"#{string_content(path)}\"]) is unnecessary; just use \"#{match[0]}\""
            end
          end

          fileutils_methods = Regexp.new(
            FileUtils.singleton_methods(false)
                     .map { |m| "(?-mix:^#{Regexp.escape(m)}$)" }
                     .join("|"),
          )
          if send_node.method_name == :system &&
             (match = regex_match_group(parameters(send_node).first, fileutils_methods))
            problem "Use the `#{match}` Ruby method instead of `#{send_node.source}`"
          end
        end

        # Check for long inreplace block vars
        def on_formula_block(block_node)
          return if block_node.method_name != :inreplace

          block_arg = block_node.arguments.children.first
          return unless block_arg.source.size > 1

          offending_node(block_node)
          problem "\"inreplace <filenames> do |s|\" is preferred over \"|#{block_arg.source}|\"."
        end

        def on_formula_revision(node)
          param = parameters(node).first
          return unless param&.numeric_type?
          return if param.value != 0

          offending_node(node)
          problem "'revision 0' should be removed"
        end

        def on_formula_version_scheme(node)
          param = parameters(node).first
          return unless param&.numeric_type?
          return if param.value != 0

          offending_node(node)
          problem "'version_scheme 0' should be removed"
        end

        def on_formula_bottle(node)
          return unless node.block_type?

          node.body.each_child_node(:send) do |send_node|
            next if send_node.method_name != :rebuild

            param = parameters(send_node).first
            next unless param&.numeric_type?
            next if param.value != 0

            offending_node(send_node)
            problem "'rebuild 0' should be removed"
          end
        end

        def on_formula_dstr(node)
          # Prefer formula path shortcuts in strings
          path = formula_path_strings(node, :share)
          if path && (match = regex_match_group(path, %r{^(/(man))/?}))
            problem "\"\#{share}#{match[1]}\" should be \"\#{#{match[2]}}\""
          end

          path = formula_path_strings(node, :prefix)
          return unless path

          if (match = regex_match_group(path, %r{^(/share/(info|man))$}))
            problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[2]}}\""
          elsif (match = regex_match_group(path, %r{^((/share/man/)(man[1-8]))}))
            problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[3]}}\""
          elsif (match = regex_match_group(path, %r{^(/(bin|include|libexec|lib|sbin|share|Frameworks))}i))
            problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[2].downcase}}\""
          end
        end

        def on_formula_if(node)
          method, param, dep_node = conditional_dependencies(node)
          return if dep_node.nil?

          dep = string_content(dep_node)
          if node.if?
            if (method == :include? && regex_match_group(param, /^with-#{dep}$/)) ||
               (method == :with? && regex_match_group(param, /^#{dep}$/))
              offending_node(dep_node.parent)
              problem "Replace #{node.source} with #{dep_node.parent.source} => :optional"
            end
          elsif node.unless?
            if (method == :include? && regex_match_group(param, /^without-#{dep}$/)) ||
               (method == :without? && regex_match_group(param, /^#{dep}$/))
              offending_node(dep_node.parent)
              problem "Replace #{node.source} with #{dep_node.parent.source} => :recommended"
            end
          end
        end

        def on_formula_depends_on(node)
          param = parameters(node).first

          key, value = destructure_hash(param)
          if !key.nil? && !value.nil? && (match = regex_match_group(value, /^(lua|perl|python|ruby)(\d*)/))
            problem "#{match[1]} modules should be vendored rather than use deprecated `#{node.source}`"
          end

          dep, option_child_nodes = hash_dep(param)
          if !dep.nil? && !option_child_nodes.empty?
            option_child_nodes.each do |option|
              find_strings(option).each do |dependency|
                next unless (match = regex_match_group(dependency, /(with(out)?-\w+|c\+\+11)/))

                problem "Dependency #{string_content(dep)} should not use option #{match[0]}"
              end
            end
          end

          problem "`depends_on` can take requirement classes instead of instances" if method_called?(node, :new)
        end

        def on_formula_const(node)
          case node.const_name
          when "MACOS_VERSION"
            offending_node(node)
            problem "Use MacOS.version instead of MACOS_VERSION"
          when "MACOS_FULL_VERSION"
            offending_node(node)
            problem "Use MacOS.full_version instead of MACOS_FULL_VERSION"
          end
        end

        def on_formula_fails_with(node)
          send_node = if node.block_type?
            node.send_node
          else
            node
          end

          return unless parameters_passed?(send_node, :llvm)

          problem "'fails_with :llvm' is now a no-op so should be removed"
        end

        def on_formula_needs(node)
          return unless parameters_passed?(node, :openmp)

          problem "'needs :openmp' should be replaced with 'depends_on \"gcc\"'"
        end

        def on_formula_def(node)
          return if node.method_name != :test

          offending_node(node)
          problem "Use new-style test definitions (test do)"
        end

        def on_formula_skip_clean(node)
          return unless parameters_passed?(node, :all)

          problem "`skip_clean :all` is deprecated; brew no longer strips symbols. " \
                  "Pass explicit paths to prevent Homebrew from removing empty folders."
        end

        def on_formula_source(processed_source)
          return unless find_method_def(processed_source.ast)

          problem "Define method #{method_name(@offensive_node)} in the class body, not at the top-level"
        end

        private

        def modifier?(node)
          return false unless node.if_type?

          node.modifier_form?
        end

        def_node_matcher :conditional_dependencies, <<~EOS
          {(if (send (send nil? :build) ${:include? :with? :without?} $(str _))
              (send nil? :depends_on $({str sym} _)) nil?)

           (if (send (send nil? :build) ${:include? :with? :without?} $(str _)) nil?
              (send nil? :depends_on $({str sym} _)))}
        EOS

        def_node_matcher :hash_dep, <<~EOS
          (hash (pair $(str _) $...))
        EOS

        def_node_matcher :destructure_hash, <<~EOS
          (hash (pair $(str _) $(sym _)))
        EOS

        def_node_matcher :formula_path_strings, <<~EOS
          {(dstr (begin (send nil? %1)) $(str _ ))
           (dstr _ (begin (send nil? %1)) $(str _ ))}
        EOS

        # Node Pattern search for Language::Node
        def_node_search :languageNodeModule?, <<~EOS
          (const (const nil? :Language) :Node)
        EOS
      end
    end

    module FormulaAuditStrict
      # This cop makes sure that no build-time checks are performed.
      #
      # @api private
      class MakeCheck < FormulaCop
        def on_formula_send(send_node)
          return unless core_tap?
          return if send_node.method_name != :system
          return if @formula_name.start_with?("lib")
          return if tap_style_exception?(:make_check_allowlist)

          params = parameters(send_node)
          return unless params.first&.str_type?
          return if params.first.value != "make"

          params[1..].each do |arg|
            next unless regex_match_group(arg, /^(checks?|tests?)$/)

            offending_node(send_node)
            problem "Formulae in homebrew/core (except e.g. cryptography, libraries) " \
                    "should not run build-time checks"
          end
        end
      end

      # This cop ensures that new formulae depending on removed Requirements are not used
      class Requirements < FormulaCop
        def on_depends_on(node)
          if depends_on_matches?(node, :java)
            problem "Formulae should depend on a versioned `openjdk` instead of :java"
          end
          problem "Formulae should depend on specific X libraries instead of :x11" if depends_on_matches?(node, :x11)
          problem "Formulae should not depend on :osxfuse" if depends_on_matches?(node, :osxfuse)
          problem "Formulae should not depend on :tuntap" if depends_on_matches?(node, :tuntap)
        end
      end
    end
  end
end

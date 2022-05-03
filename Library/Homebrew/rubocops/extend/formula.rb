# typed: true
# frozen_string_literal: true

require_relative "formula_force"
require "extend/string"
require "rubocops/shared/helper_functions"

module RuboCop
  module Cop
    # Superclass for all formula cops.
    #
    # @api private
    class FormulaCop < Base
      include RangeHelp
      include HelperFunctions

      attr_accessor :file_path

      def self.inherited(subclass)
        super(subclass)
        subclass.define_singleton_method(:joining_forces) do
          FormulaForce
        end
      end

      def on_formula_file(file_path)
        @file_path = file_path
        @formula_name = Pathname.new(file_path).basename(".rb").to_s
      end

      # Yields to block when there is a match.
      #
      # @param urls [Array] url/mirror method call nodes
      # @param regex [Regexp] pattern to match URLs
      def audit_urls(urls, regex)
        urls.each_with_index do |url_node, index|
          url_string_node = parameters(url_node).first
          url_string = string_content(url_string_node)
          match_object = regex_match_group(url_string_node, regex)
          next unless match_object

          offending_node(url_string_node.parent)
          yield match_object, url_string, index
        end
      end

      # Returns true if given dependency name and dependency type exist in given dependency method call node.
      # TODO: Add case where key of hash is an array
      def depends_on_matches?(node, name = nil, type = :any)
        return false unless node.send_type?

        first_arg = node.first_argument
        return false if first_arg.nil?

        name_match = if name
          false
        else
          true # Match only by type when name is nil
        end

        case type
        when :required
          type_match = required_dependency?(node)
          name_match ||= required_dependency_name?(node, name) if type_match
        when :build, :test, :optional, :recommended
          type_match = dependency_type_hash_match?(first_arg, type)
          name_match ||= dependency_name_hash_match?(first_arg, name) if type_match
        when :any
          type_match = true
          name_match ||= required_dependency_name?(node, name)
          name_match ||= dependency_name_hash_match?(first_arg, name)
        else
          type_match = false
        end

        @offensive_node = node if type_match || name_match
        type_match && name_match
      end

      def_node_matcher :required_dependency?, <<~EOS
        (send nil? :depends_on ({str sym} _))
      EOS

      def_node_matcher :required_dependency_name?, <<~EOS
        (send nil? :depends_on ({str sym} %1))
      EOS

      def_node_matcher :dependency_type_hash_match?, <<~EOS
        (hash (pair ({str sym} _) ({str sym} %1)))
      EOS

      def_node_matcher :dependency_name_hash_match?, <<~EOS
        (hash (pair ({str sym} %1) (...)))
      EOS

      # Returns the sha256 str node given a sha256 call node.
      def get_checksum_node(call)
        return if parameters(call).empty? || parameters(call).nil?

        if parameters(call).first.str_type?
          parameters(call).first
        # sha256 is passed as a key-value pair in bottle blocks
        elsif parameters(call).first.hash_type?
          if parameters(call).first.keys.first.value == :cellar
            # sha256 :cellar :any, :tag "hexdigest"
            parameters(call).first.values.last
          elsif parameters(call).first.keys.first.is_a?(RuboCop::AST::SymbolNode)
            # sha256 :tag "hexdigest"
            parameters(call).first.values.first
          else
            # Legacy bottle block syntax
            # sha256 "hexdigest" => :tag
            parameters(call).first.keys.first
          end
        end
      end

      # Returns true if the formula is versioned.
      def versioned_formula?
        @formula_name.include?("@")
      end

      # Returns the formula tap.
      def formula_tap
        return unless (match_obj = @file_path.match(%r{/(homebrew-\w+)/}))

        match_obj[1]
      end

      def core_tap?
        formula_tap == "homebrew-core"
      end

      # Returns whether the given formula exists in the given style exception list.
      # Defaults to the current formula being checked.
      def tap_style_exception?(list, formula = nil)
        if @tap_style_exceptions.nil? && !formula_tap.nil?
          @tap_style_exceptions = {}

          style_exceptions_dir = "#{File.dirname(File.dirname(@file_path))}/style_exceptions/*.json"
          Pathname.glob(style_exceptions_dir).each do |exception_file|
            list_name = exception_file.basename.to_s.chomp(".json").to_sym
            list_contents = begin
              JSON.parse exception_file.read
            rescue JSON::ParserError
              nil
            end
            next if list_contents.nil? || list_contents.count.zero?

            @tap_style_exceptions[list_name] = list_contents
          end
        end

        return false if @tap_style_exceptions.nil? || @tap_style_exceptions.count.zero?
        return false unless @tap_style_exceptions.key? list

        @tap_style_exceptions[list].include?(formula || @formula_name)
      end
    end
  end
end

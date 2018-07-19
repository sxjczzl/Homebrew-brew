require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks if redundant components are present and other component errors
      #
      # - `url|checksum|mirror` should be inside `stable` block
      # - `head` and `head do` should not be simultaneously present
      # - `bottle :unneeded/:disable` and `bottle do` should not be simultaneously present
      # - `stable do` should not be present without a `head` or `devel` spec
      # - `head do` should not be used for only one line

      class ComponentsRedundancy < FormulaCop
        HEAD_MSG = "`head` and `head do` should not be simultaneously present".freeze
        BOTTLE_MSG = "`bottle :modifier` and `bottle do` should not be simultaneously present".freeze
        STABLE_MSG = "`stable do` should not be present without a `head` or `devel` spec".freeze
        HEAD_BLOCK_MSG = "`head do` should not be used for only one line".freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          stable_block = find_block(body_node, :stable)
          head_block = find_block(body_node, :head)
          if stable_block
            [:url, :sha256, :mirror].each do |method_name|
              problem "`#{method_name}` should be put inside `stable` block" if method_called?(body_node, method_name)
            end
          end

          problem HEAD_MSG if method_called?(body_node, :head) &&
                              find_block(body_node, :head)

          problem BOTTLE_MSG if method_called?(body_node, :bottle) &&
                                find_block(body_node, :bottle)

          # 2 is the block size if it only contains one line
          problem HEAD_BLOCK_MSG if head_block && block_size(head_block) == 2

          return if method_called?(body_node, :head) ||
                    find_block(body_node, :head) ||
                    find_block(body_node, :devel)
          problem STABLE_MSG if stable_block
        end
      end
    end
  end
end

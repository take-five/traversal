module Traversal
  module ActsAsTraversable
    # == Synopsys
    # Mix-in <tt>#traverse</tt> method
    #
    # == Example
    #   class TreeNode
    #     attr_accessor :siblings
    #
    #     acts_as_traversable
    #   end
    #
    #   t = TreeNode.new
    #   t.traverse            # equivalent to Traversal::Description.new.traverse(t)
    #   t.traverse(:siblings) # equivalent to Traversal::Description.new.traverse(t).follow(:siblings)
    def acts_as_traversable
      include InstanceMethods
    end
    alias acts_like_traversable acts_as_traversable

    module InstanceMethods
      # Shortcut method, simplified interface to Traversal::Description
      #
      # == Example
      #   class TreeNode
      #     attr_accessor :siblings
      #
      #     acts_as_traversable
      #   end
      #
      #   t = TreeNode.new
      #   t.traverse            # equivalent to Traversal::Description.new.traverse(t)
      #   t.traverse(:siblings) # equivalent to Traversal::Description.new.traverse(t).follow(:siblings)
      def traverse(relation = nil)
        Traversal::Description.new.traverse(self).tap { |desc| desc.follow(relation) if relation }
      end
    end
  end
end
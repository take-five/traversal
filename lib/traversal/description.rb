# coding: utf-8
module Traversal
  # Traversal description
  class Description
    include Enumerable

    DEPTH_FIRST = 0
    BREADTH_FIRST = 1

    attr_reader :start_node, :relation

    # Create blank traversal description
    def initialize
      @exclude = []
      @prune = []
      @stop_before = []
      @stop_after = []

      @start_node = nil
      @relation = nil

      @order = DEPTH_FIRST
    end

    # Declare a traversal start point. From which node you want to follow relations?
    def traverse(start_node)
      tap { @start_node = start_node }
    end

    # Declare which relation you want to follow in your traversal.
    # It can be Symbol, Method, Proc or block.
    #
    # Relation should return something enumerable, otherwise it will be ignored in traversal.
    #
    # == Example
    #   traversal.follow(:children)               # for each node will call node#children method
    #   traversal.follow { |node| node.children } # same effect
    def follow(relation = nil, &blk)
      tap { @relation = condition("Relation", relation, &blk) }
    end

    # Declare exclude condition. Which nodes you want to
    # exclude (ignore them but not their relations) from your traversal?
    def exclude(cond = nil, &blk)
      tap { @exclude << condition("Exclude condition", cond, &blk) }
    end

    # Declare prune condition. Which nodes relations you want to ignore?
    #
    # Example:
    #   traversal.follow(:children).
    #   prune { |node| node.name == "A" } # node "A" will be included, but not its children
    def prune(cond = nil, &blk)
      tap { @prune << condition("Prune condition", cond, &blk) }
    end

    # Declare exclude AND prune condition.
    # Matching node and its relations will be excluded from traversal.
    def exclude_and_prune(cond = nil, &blk)
      exclude(cond, &blk)
      prune(cond, &blk)
    end
    alias prune_and_exclude exclude_and_prune

    # Declare +stop pre-condition+.
    # When met, matched node will be excluded from traversal and iteration will be stopped.
    def stop_before(cond = nil, &blk)
      tap { @stop_before << condition("Stop condition", cond, &blk) }
    end

    # Declare +stop post-condition+.
    # When met, matched node will be included in traversal and iteration will be stopped.
    def stop_after(cond = nil, &blk)
      tap { @stop_after << condition("Stop condition", cond, &blk) }
    end

    # Declare traversal order strategy as +depth first+
    def depth_first
      tap { @order = DEPTH_FIRST }
    end

    # Declare traversal order strategy as +breadth first+
    def breadth_first
      tap { @order = BREADTH_FIRST }
    end

    def each
      assert_complete_description

      iter = Traversal::Iterator.new(self)

      if iterator?
        iter.each do |node|
          yield node
        end
      else
        iter
      end
    end

    # Predicates section

    # Does node matches one of stop conditions?
    def stop?(node, type = :before) #:nodoc:
      (type == :after ? @stop_after : @stop_before).any? { |cond| cond[node] }
    end

    def exclude?(node) #:nodoc:
      @exclude.any? { |cond| cond[node] }
    end

    def prune?(node) #:nodoc:
      @prune.any? { |cond| cond[node] }
    end

    def breadth_first? #:nodoc:
      @order == BREADTH_FIRST
    end

    private
    def condition(name, arg, &blk) #:nodoc:
      raise TypeError, "#{name} must be Symbol, Method, Proc or block" unless
          (arg ||= blk).respond_to?(:to_proc)

      arg.to_proc
    end

    def assert_complete_description #:nodoc:
      raise IncompleteDescription, "Traversal description should contain start node. Use #traverse method" unless @start_node
      raise IncompleteDescription, "Traversal description should contain relation. Use #follow method" unless @relation
    end
  end
end
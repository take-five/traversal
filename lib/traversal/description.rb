# coding: utf-8

require "forwardable"

module Traversal
  # Traversal description
  class Description
    class EmptyArgument; end

    extend Forwardable
    include Enumerable

    DEPTH_FIRST = 0
    BREADTH_FIRST = 1

    attr_reader :start_node, :relations
    def_delegators :each, :[], :at, :empty?,
                          :fetch, :find_index, :index,
                          :last, :reverse, :values_at

    # Create blank traversal description
    def initialize
      @exclude        = []
      @include_only   = []

      @prune          = []
      @expand_only    = []
      @stop_before    = []
      @stop_after     = []

      @start_node     = nil
      @relations      = []

      @order          = DEPTH_FIRST
      @uniq           = true
    end

    # Tests equality of traversal descriptions
    def ==(other)
      return super unless other.is_a?(Description)

      [:@start_node, :@relations, :@include_only,
       :@exclude, :@prune, :@stop_before, :@uniq,
       :@stop_after, :@order, :@expand_only].all? do |sym|
        instance_variable_get(sym) == other.instance_variable_get(sym)
      end
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
    def follow(*relations, &blk)
      raise ArgumentError, 'arguments or block expected' if relations.empty? && !block_given?

      tap do
        relations << blk if block_given?

        relations.each do |relation|
          @relations << condition(relation)
        end
        #@relations = condition(*relations, &blk)
      end
    end

    # Declare exclude condition. Which nodes you want to
    # exclude (ignore them but not their relations) from your traversal?
    def exclude(*nodes, &blk)
      tap { @exclude << condition(*nodes, &blk) }
    end

    # Declare inverted exclude condition. Which nodes you want to keep?
    def include_only(*nodes, &blk)
      tap { @include_only << condition(*nodes, &blk) }
    end
    alias exclude_unless include_only

    # Declare which nodes you want to expand. Others will be pruned.
    def expand_only(*nodes, &blk)
      tap { @expand_only << condition(*nodes, &blk) }
    end

    # Declare prune condition. Which nodes relations you want to ignore?
    #
    # Example:
    #   traversal.follow(:children).
    #   prune { |node| node.name == "A" } # node "A" will be included, but not its children
    def prune(*nodes, &blk)
      tap { @prune << condition(*nodes, &blk) }
    end

    # Declare exclude AND prune condition.
    # Matching node and its relations will be excluded from traversal.
    def exclude_and_prune(*nodes, &blk)
      exclude(*nodes, &blk)
      prune(*nodes, &blk)
    end
    alias prune_and_exclude exclude_and_prune

    # Declare +stop pre-condition+.
    # When met, matched node will be excluded from traversal and iteration will be stopped.
    def stop_before(*nodes, &blk)
      tap { @stop_before << condition(*nodes, &blk) }
    end

    # Declare +stop post-condition+.
    # When met, matched node will be included in traversal and iteration will be stopped.
    def stop_after(*nodes, &blk)
      tap { @stop_after << condition(*nodes, &blk) }
    end

    # Declare traversal order strategy as +depth first+
    def depth_first
      tap { @order = DEPTH_FIRST }
    end

    # Declare traversal order strategy as +breadth first+
    def breadth_first
      tap { @order = BREADTH_FIRST }
    end

    # Set uniqueness behaviour
    # By default it is set to +true+
    def uniq(v = true)
      tap { @uniq = !!v }
    end

    # Iterate through nodes defined by DSL and optionally execute given +block+ for each node.
    def each # :yields: node
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

    def include_node?(node) #:nodoc:
      @include_only.all? { |cond| cond[node] } &&
      @exclude.none? { |cond| cond[node] }
    end

    def exclude_node?(node) #:nodoc:
      !include_node?(node)
    end

    def expand_node?(node) #:nodoc:
      @expand_only.all? { |cond| cond[node] } &&
      @prune.none? { |cond| cond[node] }
    end

    def prune_node?(node) #:nodoc:
      !expand_node?(node)
    end

    def breadth_first? #:nodoc:
      @order == BREADTH_FIRST
    end

    def uniq? #:nodoc:
      @uniq
    end

    private
    def condition(*args, &blk) #:nodoc:
      # on empty argument use given block
      args << blk if block_given?
      raise ArgumentError, 'arguments or block expected' if args.empty?

      args.length == 1 ? arg_to_proc(args.first) : args_to_proc(args)
    end

    def assert_complete_description #:nodoc:
      raise IncompleteDescription, "Traversal description should contain start node. Use #traverse method" unless @start_node
      raise IncompleteDescription, "Traversal description should contain relation(s). Use #follow method" if @relations.empty?
    end

    def args_to_proc(args)
      procs = args.map { |arg| arg_to_proc(arg) }
      proc { |node| procs.any? { |pr| pr[node] } }
    end

    # convert argument to callable proc
    def arg_to_proc(arg) #:nodoc:
      return arg.to_proc if arg.respond_to?(:to_proc)

      [:===, :==, :eql?].each do |meth|
        return arg.method(meth) if arg.respond_to?(meth)
      end

      raise TypeError, 'argument must respond to one of the following method: #to_proc, #===, #==, #eql?'
    end
  end
end
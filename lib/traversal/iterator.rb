# coding: utf-8

require "enumerator"
require "forwardable"

module Traversal
  # Traversal iterator.
  class Iterator < Enumerator #:nodoc: all
    extend Forwardable

    def_delegators :to_ary!, :[], :at, :empty?,
                             :fetch, :find_index, :index,
                             :last, :reverse, :values_at

    # Create new traversal iterator from traversal description
    def initialize(description)
      raise TypeError,
            'Traversal::Description expected, %s given' % description.class.name \
            unless description.is_a?(Traversal::Description)

      @description = description
      start_node = @description.start_node

      # Map of visited nodes
      @visited = {}

      # Create underlying Enumerator
      @enumerator = Enumerator.new do |yielder|
        @yielder = yielder

        begin
          yield_node(start_node)

          expand_node(start_node) if @description.expand_node?(start_node)
        rescue StopIteration
          # ignore
        end
      end

      # Wrap underlying enumerator
      super() do |y|
        @enumerator.each { |e| y << e }
      end
    end

    private
    def push(node) #:nodoc:
      @visited[node] = true if @description.uniq? # memo visited node

      @yielder.yield(node)
    end

    def yield_node(node) #:nodoc:
      # check stop pre-condition
      raise StopIteration if @description.stop?(node, :before)

      # do yield
      push(node) unless @description.exclude_node?(node) || visited?(node)

      # check stop post-condition
      raise StopIteration if @description.stop?(node, :after)
    end

    # Expand node
    def expand_node(node) #:nodoc:
      if @description.breadth_first?
        expand_breadth(node)
      else
        expand_depth(node)
      end
    end

    # Expand node with DEPTH_FIRST strategy
    def expand_depth(node) #:nodoc:
      relations_for(node).each do |rel|
        yield_node(rel)

        expand_node(rel) unless @description.prune_node?(rel)
      end
    end

    # Expand node with BREADTH_FIRST strategy
    def expand_breadth(node) #:nodoc:
      cached_relations = []

      # 1. yield direct relations first
      relations_for(node).each do |rel|
        yield_node(rel)

        # memoize relation for next iteration
        cached_relations << rel unless @description.prune_node?(rel)
      end

      # 2. dig deeper
      cached_relations.each do |rel|
        expand_breadth(rel)
      end
    end

    # Expand relations for node
    def relations_for(node) #:nodoc:
      Enumerator.new do |yielder|
        @description.relations.each do |relation_accessor|
          begin
            relations  = relation_accessor[node]
            enumerable = relations.is_a?(Enumerable) ? relations : [relations].compact

            enumerable.each { |e| yielder << e unless visited?(e) }
          rescue NoMethodError
            # ignore errors on relation_accessor[node]
          end
        end
      end
    end

    def visited?(node) #:nodoc:
      @description.uniq? && @visited.key?(node)
    end

    # convert underlying enumerator to array
    def to_ary! #:nodoc:
      @enumerator = @enumerator.to_a unless @enumerator.is_a?(Array)
      @enumerator
    end
  end # module Iterator
end # module Traversal
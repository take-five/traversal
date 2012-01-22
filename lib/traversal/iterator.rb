# coding: utf-8

require "enumerator"

module Traversal
  # Traversal iterator.
  class Iterator < Enumerator
    # Create new traversal iterator from traversal description
    def initialize(description)
      raise TypeError,
            'Traversal::Description expected, %s given' % description.class.name \
            unless description.is_a?(Traversal::Description)

      @description = description
      start_node = @description.start_node

      # Create Enumerator
      super() do |yielder|
        @yielder = yielder

        begin
          yield_node(start_node)

          expand_node(start_node)
        rescue StopIteration
          # ignore
        end
      end
    end

    private
    def push(*args) #:nodoc:
      @yielder.yield(*args)
    end

    def yield_node(node) #:nodoc:
      # check stop pre-condition
      raise StopIteration if @description.stop?(node, :before)

      # do yield
      push(node) unless @description.exclude?(node)

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

        expand_node(rel) unless @description.prune?(rel)
      end
    end

    # Expand node with BREADTH_FIRST strategy
    def expand_breadth(node) #:nodoc:
      cached_relations = []

      # 1. yield direct relations first
      relations_for(node).each do |rel|
        yield_node(rel)

        # memoize relation for next iteration
        cached_relations << rel unless @description.prune?(rel)
      end

      # 2. dig deeper
      cached_relations.each do |rel|
        expand_breadth(rel)
      end
    end

    # Expand relations for node
    def relations_for(node) #:nodoc:
      relation = @description.relation[node]

      relation.is_a?(Enumerable) ? relation : []
    end
  end
end
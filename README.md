# Synopsys
Simple traversal API for pure Ruby objects. Also it can be used it with ActiveRecord or DataMapper (or any other ORM).

# Installation
Install it via rubygems:

```bash
gem install traversal
```

In your Gemfile:

```ruby
gem 'traversal'
```

# Usage
Imagine tree(-ish) structure:

```yaml
plants:
  vegetables:
    - cucumber
    - tomato
  fruits:
    - apple
    - banana
```

Let's create tree structure from above in Ruby:

```ruby
class Node
  attr_reader :name, :children

  def initialize(name)
    @name = name
    @children = []
  end
end

# create data now
root       = Node.new('plants')
vegetables = Node.new('vegetables')
fruits     = Node.new('fruits')
cucumber   = Node.new('cucumber')
tomato     = Node.new('tomato')
apple      = Node.new('apple')
banana     = Node.new('banana')

root.children << vegetables << fruits
vegetables.children << cucumber << tomato
fruits.children << apple << banana
```

So, we have a simple tree with `root` element on the top of it.
Now let's create a <b>traversal description</b>.

```ruby
require 'traversal'

traversal = Traversal::Description.new
traversal.traverse(root).    # start from root node
          follow(:children)  # move forward via children relations
```

Or you can use shortcut:

```ruby
class Node
  acts_as_traversable
end

traversal = root.traverse(:children) # same as above
```

It's a minimal traversal description. It has <b>start node</b> and <b>relation</b> pointer (`children`, in this case).
Traversal description is <i>Enumerable</i> (iterable) object. Let's examine our traverse:

```ruby
traversal.map(&:name) # should be equal to [root, vegetables, cucumber, tomato, fruits, apple, banana]
```


Let's look closer:

1. We are starting from `root` node. It's first element.
1. Traversal cursor <i>follows</i> root's relation `children` and moves to the first child of `root`: `vegetables`
1. Cursor moves deeper (it is default strategy), to first child of `vegetables` node: `cucumber`
1. `cucumber` has no children, traversal cursor moves to the next child of `vegetables`: `tomato`
1. `tomato` has no children, and `vegetables` has no more unvisited descendant nodes, so the traversal cursor moves to the next child of `root`: `fruits`
1. Traversal cursor visits children of `fruits`: `apple` and `banana`
1. All nodes are visited, cursor closed.



If you want the cursor to visit all children before visiting grandchildren, then you have to declare `breadth_first` traversal visiting strategy:

```ruby
traversal.breadth_first # in opposite of traversal.depth_first
```

You can exclude nodes (but allow cursor to follow relations) from final result:

```ruby
traversal.exclude { |node| node.children.length > 0 } # all nodes with children will be excluded from result

# opposite version:
traversal.include_only { |node| node.children.length > 0 }
```

You can prune away (do not expand, i.e. do not <i>follow</i> node's <i>relations</i>) any node (but leave the node in final result):

```ruby
traversal.prune(vegetables).
          map(&:name) # will produce [root, vegetables, fruits, apple, banana]

# opposite version:
traversal.expand_only(root, vegetables) # it means: expand root node and vegetables node, prune away other nodes
```

Or, you can exclude node and prune away it's children:

```ruby
traversal.prune_and_exclude { |node| node.name == "vegetables" }.
          map(&:name) # will produce [root, fruits, apple, banana]
```

Also, you can mark any node as "loop terminator":

```ruby
traversal.stop_before(vegetables).to_a # will produce only [root]
traversal.stop_after(vegetables).to_a # will produce [root, vegetables]
```

By default traverser does not visit already visited nodes, but you can change that behavior:

```ruby
traversal.uniq(false)
```

# Real world example

```ruby
require "traversable"

class Page < ActiveRecord::Base
  acts_as_tree
  acts_as_traversable
end

lim = 15

# traverse through first 15 descendant
Page.root.traverse(:children).
          exclude(:root?).
          exclude_and_prune(:is_deleted?).
          stop_after { (lmt -= 1) == 0 }

# traverse through whole tree, yield only leaf nodes
Page.root.traverse(:children).
          exclude_and_prune(:is_deleted?).
          include_only { |page| page.children.empty? }

leaf = Page.last # not root node

# traverse through ancestors, exclude last ancestor and its children
leaf.traverse(:parent).
     exclude(:root?).
     exclude { |node| node.member_of?(root.children) }
```
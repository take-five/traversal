require "traversal/version"

module Traversal
  autoload :Description,       "traversal/description"
  autoload :Iterator,          "traversal/iterator"
  autoload :ActsAsTraversable, "traversal/acts_as_traversable"

  class IncompleteDescription < Exception; end
end

Object.extend(Traversal::ActsAsTraversable)
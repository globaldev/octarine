require "minitest/autorun"
require_relative "../../lib/octarine"

module Octarine
  class PathTemplateTest < MiniTest::Unit::TestCase
    
    def test_equality
      a = PathTemplate.new("/foo/:id")
      b = PathTemplate.new("/foo/:id")
      c = PathTemplate.new("/bar/:id")
      
      assert(a == b)
      refute(a == c)
    end
    
    def test_triple_equals
      template = PathTemplate.new("/blog/:year/:month/:day")
      
      assert(template === "/blog/2011/11/4")
      refute(template === "/posts/1")
    end
    
    def test_dup
      template = PathTemplate.new("/foo/:id")
      
      copy = template.dup
      
      assert(template == copy)
      refute_same(template, copy)
    end
    
  end
end

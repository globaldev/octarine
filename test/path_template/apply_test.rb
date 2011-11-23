require "minitest/autorun"
require_relative "../../lib/octarine/path_template"

module Octarine
  class PathTemplateApplyTest < MiniTest::Unit::TestCase
    
    def test_basic_variable
      template = PathTemplate.new("/test/:variable")
      
      result = template.apply(variable: 1)
      
      assert_equal("/test/1", result)
    end
    
    def test_multiple_variables
      template = PathTemplate.new("/test/:test_num/example/:example_num")
      
      result = template.apply(test_num: 2, example_num: 1)
      
      assert_equal("/test/2/example/1", result)
    end
    
    def test_positional_variables
      template = PathTemplate.new("/foo/:a/baz/:b")
      
      result = template.apply("bar", "qux")
      
      assert_equal("/foo/bar/baz/qux", result)
    end
    
    def test_glob
      template = PathTemplate.new("/:var/b/*rest")
      
      result = template.apply(var: "a", rest: ["c", "d"])
      
      assert_equal("/a/b/c/d", result)
    end
    
    def test_positional_glob
      template = PathTemplate.new("/:val/two/*rest")
      
      result = template.apply("one", "three", "four")
      
      assert_equal("/one/two/three/four", result)
    end
    
    def test_format
      template = PathTemplate.new("/:folder/:file.format")
      
      result = template.apply(folder: "photos", file: "me", format: "jpg")
      
      assert_equal("/photos/me.jpg", result)
    end
    
    def test_positional_format
      template = PathTemplate.new("/:path/:to.ext")
      
      result = template.apply(path: "notes", to: "todo", ext: "txt")
      
      assert_equal("/notes/todo.txt", result)
    end
    
    def test_glob_with_format
      template = PathTemplate.new("/:root/*path.format")
      
      result = template.apply(root: "blog", path: [2011, 11, 4], format: "html")
      
      assert_equal("/blog/2011/11/4.html", result)
    end
    
    def test_positional_glob_with_format
      template = PathTemplate.new("/:root/*path.format")
      
      result = template.apply("blog", 2011, 11, 4, "html")
      
      assert_equal("/blog/2011/11/4.html", result)
    end
    
    def test_no_leading_slash
      template = PathTemplate.new(":foo/:bar")
      
      result = template.apply(foo: "baz", bar: "qux")
      
      assert_equal("baz/qux", result)
    end
    
    def test_query_string
      template = PathTemplate.new("/:var")
      
      result = template.apply(var: "foo", bar: "baz", qux: "quxx")
      
      assert_equal("/foo?bar=baz&qux=quxx", result)
    end
    
    def test_out_of_place_format
      assert_raises(PathTemplate::BadTemplateError) do
        PathTemplate.new("/folder.format/:file")
      end
    end
    
    def test_out_of_place_glob
      assert_raises(PathTemplate::BadTemplateError) do
        PathTemplate.new("/*rest/:file")
      end
    end
    
    def test_double_glob
      assert_raises(PathTemplate::BadTemplateError) do
        PathTemplate.new("/*rest/*more")
      end
    end
    
    def test_base_path
      template = PathTemplate.new("/")
      
      result = template.apply
      
      assert_equal("/", result)
    end
    
    def test_base_path_with_query
      template = PathTemplate.new("/")
      
      result = template.apply(foo: "bar")
      
      assert_equal("/?foo=bar", result)
    end
    
  end
end

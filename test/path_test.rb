require "minitest/autorun"
require_relative "../lib/octarine/path"

module Octarine
  class PathTest < MiniTest::Unit::TestCase
    
    def test_hash_access
      path = Path.new("/users/:user_id/messages/:message_id", "/users/1/messages/2?page=3")
      
      assert_equal("1", path[:user_id])
      assert_equal("2", path[:message_id])
      assert_equal("3", path["page"])
    end
    
    def test_method_access
      path = Path.new("/users/:user_id/messages/:message_id", "/users/1/messages/2?page=3")
      
      assert_equal("1", path.user_id)
      assert_equal("2", path.message_id)
      assert_raises(NoMethodError) {path.page}
    end
    
    def test_to_s
      path = Path.new("/users/:user_id/messages/:message_id", "/users/1/messages/2?page=3")
      
      assert_equal("/users/1/messages/2?page=3", path.to_s)
    end
    
    def test_without
      path = Path.new("/users/:user_id/messages", "/users/1/messages")
      
      path_without_users = path.without("users")
      
      assert_equal("/1/messages", path_without_users.to_s)
    end
    
    def test_without_symbol
      path = Path.new("/users/:user_id/messages", "/users/1/messages")
      
      path_without_user_id = path.without(:user_id)
      
      assert_equal("/users/messages", path_without_user_id.to_s)
    end
    
    def test_merge
      path = Path.new("/users/:user_id/messages", "/users/1/messages")
      
      merged_path = path.merge(:user_id => 2, "page" => 3)
      
      assert_equal("/users/2/messages?page=3", merged_path.to_s)
    end
    
    def test_plus
      path = Path.new("/users/:user_id", "/users/1")
      
      path_plus = path + "messages"
      
      assert_equal("/users/1/messages", path_plus.to_s)
    end
    
    def test_equal
      a = Path.new("/users/:user_id", "/users/1")
      b = Path.new("/users/:user_id", "/users/1")
      c = Path.new("/users/:user_id", "/users/2")
      
      assert_equal(a, b)
      refute_equal(a, c)
    end
    
    def test_case_equal
      path = Path.new("/users/:user_id", "/users/1")
      
      assert(path === "/users/1")
      refute(path === "/users/2")
    end
    
  end
end

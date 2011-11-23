require "minitest/autorun"
require_relative "../lib/octarine/response"

module Octarine
  class ResponseTest < MiniTest::Unit::TestCase
    
    def test_update
      response = Response.new({"name" => "arthur"})
      
      response.update("name") {|name| name.capitalize}
      
      assert_equal({"name" => "Arthur"}, response.body)
    end
    
    def test_update_traverse_hash
      response = Response.new({"user" => {"name" => "drof"}})
      
      response.update("user.name") {|name| name.reverse.capitalize}
      
      assert_equal({"user" => {"name" => "Ford"}}, response.body)
    end
    
    def test_update_no_arg
      response = Response.new([1,2,3])
      
      response.update {|body| {"data" => body}}
      
      assert_equal({"data" => [1,2,3]}, response.body)
    end
    
    def test_update_traverse_array
      response = Response.new([1,2,3])
      names = {1 => "Arthur", 2 => "Ford", 3 => "Zaphod"}
      
      response.update(".") {|i| names[i]}
      
      assert_equal(["Arthur", "Ford", "Zaphod"], response.body)
    end
    
    def test_update_traverse_array_in_hash
      response = Response.new({"data" => [1,2,3]})
      names = {1 => "Arthur", 2 => "Ford", 3 => "Zaphod"}
      
      response.update("data.") {|i| names[i]}
      
      assert_equal({"data" => ["Arthur", "Ford", "Zaphod"]}, response.body)
    end
    
    def test_update_traverse_hash_in_array_in_hash
      response = Response.new({"data" => [{"user" => "1234", "message" => "hi"}, {"user" => "5678", "message" => "hello"}]})
      user_details = {"1234" => {"id" => "1234", "name" => "Arthur"}, "5678" => {"id" => "5678", "name" => "Ford"}}
      
      response.update("data.user") {|id| user_details[id]}
      
      expected = {"data" => [{"user" => {"id" => "1234", "name" => "Arthur"}, "message" => "hi"}, {"user" => {"id" => "5678", "name" => "Ford"}, "message" => "hello"}]}
      assert_equal(expected, response.body)
    end
    
    def test_to_ary
      response = Response.new("foo", {"content-length" => "3", "content-type" => "text/plain"}, 200)
      
      status, headers, body = response
      
      assert_equal(200, status)
      assert_equal({"content-length" => "3", "content-type" => "text/plain"}, headers)
      assert_equal(["foo"], body)
    end
    
    def test_to_a
      response = Response.new("foo", {"content-length" => "3", "content-type" => "text/plain"}, 200)
      
      status, headers, body = *response
      
      assert_equal(200, status)
      assert_equal({"content-length" => "3", "content-type" => "text/plain"}, headers)
      assert_equal(["foo"], body)
    end
    
    def test_to_array_access
      response = Response.new("foo", {"content-length" => "3", "content-type" => "text/plain"}, 200)
      
      assert_equal(200, response[0])
      assert_equal({"content-length" => "3", "content-type" => "text/plain"}, response[1])
      assert_equal(["foo"], response[2])
    end
    
    def test_array_set
      response = Response.new
      
      response[0] = 200
      response[1] = {"content-length" => "3", "content-type" => "text/plain"}
      response[2] = ["foo"]
      
      assert_equal(200, response.status)
      assert_equal({"content-length" => "3", "content-type" => "text/plain"}, response.header)
      assert_equal(["foo"], response.body)
      assert_raises(ArgumentError) {response[3] = nil}
    end
    
    def test_to_hash_access
      response = Response.new("foo", {"content-length" => "3", "content-type" => "text/plain"}, 200)
      
      assert_equal("3", response["content-length"])
      assert_equal("text/plain", response["content-type"])
    end
    
    def test_hash_set
      response = Response.new
      
      response["content-length"] = "3"
      response["content-type"] = "text/plain"
      
      assert_equal({"content-length" => "3", "content-type" => "text/plain"}, response.header)
    end
    
  end
end

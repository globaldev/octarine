require "net/http"

module Octarine
  class SimpleHTTP
    Response = Struct.new(:status, :headers, :body)
    
    def initialize(url, options={})
      unless url.respond_to?(:to_str)
        options = url
        url = options[:url]
      end
      @host, @port = url.to_s.split(/:/)
    end
    
    def head(path, headers={})
      request(Net::HTTP::Head.new(path, headers))
    end
    
    def get(path, headers={})
      request(Net::HTTP::Get.new(path, headers))
    end
    
    def post(path, body=nil, headers={})
      req = Net::HTTP::Post.new(path, headers)
      req.body = body if body
      request(req)
    end
    
    def put(path, body=nil, headers={})
      req = Net::HTTP::Put.new(path, headers)
      req.body = body if body
      request(req)
    end
    
    def delete(path, headers={})
      request(Net::HTTP::Delete.new(path, headers))
    end
    
    private
    def request(request)
      response = Net::HTTP.start(@host, @port) {|http| http.request(request)}
      headers = Hash[response.to_hash.map {|h,k| [h, k.join("\n")]}]
      Response.new(response.code, headers, response.body)
    end
    
  end
end

require "net/http"

module Octarine # :nodoc:
  
  # SimpleHTTP is a bare-bones implementation of a simple http client, designed
  # to be easily replaceable with another implementation.
  # 
  class SimpleHTTP
    Response = Struct.new(:status, :headers, :body)
    
    # :call-seq: SimpleHTTP.new(url, options={}) -> simple_http
    # SimpleHTTP.new(options) -> simple_http
    # 
    # Create a SimpleHTTP instace with either a url and options or options with
    # a :url key.
    # 
    def initialize(url, options={})
      unless url.respond_to?(:to_str)
        options = url
        url = options[:url]
      end
      @host, @port = url.to_s.split(/:/)
    end
    
    # :call-seq: simple_http.head(path, headers={}) -> response
    # 
    # Perform a HEAD request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def head(path, headers={})
      request(Net::HTTP::Head.new(path, headers))
    end
    
    # :call-seq: simple_http.get(path, headers={}) -> response
    # 
    # Perform a GET request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def get(path, headers={})
      request(Net::HTTP::Get.new(path, headers))
    end
    
    # :call-seq: simple_http.post(path, body=nil, headers={}) -> response
    # 
    # Perform a POST request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def post(path, body=nil, headers={})
      req = Net::HTTP::Post.new(path, headers)
      req.body = body if body
      request(req)
    end
    
    # :call-seq: simple_http.put(path, body=nil, headers={}) -> response
    # 
    # Perform a PUT request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def put(path, body=nil, headers={})
      req = Net::HTTP::Put.new(path, headers)
      req.body = body if body
      request(req)
    end
    
    # :call-seq: simple_http.delete(path, headers={}) -> response
    # 
    # Perform a DELETE request, returns a response that responds to #status,
    # #headers, and #body
    # 
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

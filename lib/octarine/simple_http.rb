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
      run_request(:head, path, nil, headers)
    end
    
    # :call-seq: simple_http.get(path, headers={}) -> response
    # 
    # Perform a GET request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def get(path, headers={})
      run_request(:get, path, nil, headers)
    end
    
    # :call-seq: simple_http.post(path, body=nil, headers={}) -> response
    # 
    # Perform a POST request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def post(path, body=nil, headers={})
      run_request(:post, path, body, headers)
    end
    
    # :call-seq: simple_http.put(path, body=nil, headers={}) -> response
    # 
    # Perform a PUT request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def put(path, body=nil, headers={})
      run_request(:put, path, body, headers)
    end
    
    # :call-seq: simple_http.delete(path, headers={}) -> response
    # 
    # Perform a DELETE request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def delete(path, headers={})
      run_request(:delete, path, nil, headers)
    end
    
    # :call-seq: simple_http.options(path, headers={}) -> response
    # 
    # Perform an OPTIONS request, returns a response that responds to #status,
    # #headers, and #body
    # 
    def options(path, headers)
      run_request(:options, path, nil, headers)
    end
    
    # :call-seq: simple_http.run_request(method, path, body, headers) -> res
    # 
    # Perform request, returns a response that responds to #status, #headers,
    # and #body
    # 
    def run_request(method, path, body, headers)
      klass = Net::HTTP.const_get(method.to_s.capitalize)
      req.klass.new(path, headers)
      req.body = body if body
      request(req)
    end
    
    private
    def request(request)
      response = Net::HTTP.start(@host, @port) {|http| http.request(request)}
      headers = Hash[response.to_hash.map {|h,k| [h, k.join("\n")]}]
      Response.new(response.code, headers, response.body)
    end
    
  end
end

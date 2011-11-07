require "forwardable"
require_relative "simple_http"
require_relative "response"

module Octarine # :nodoc:
  
  # Octarine::Endpoint is a wrapper round a http client that presents a DSL for
  # generating paths and making requests.
  # 
  # Examples:
  # 
  #   # GET users/123/messages/567
  #   endpoint.users(123).messages[567]
  # 
  #   # GET 123/details/address
  #   endpoint.(123).details["address"]
  # 
  #   # POST users/123/messages
  #   endpoint.users(123).post("messages", body)
  # 
  class Endpoint
    attr_accessor :path
    protected :path, :path=
    attr_reader :client
    private :client
    
    extend Forwardable
    def_delegators :@client, :host, :port
    
    # :call-seq: Endpoint.new(host) -> endpoint
    # Endpoint.new(client) -> endpoint
    # 
    # Create a new Endpoint instance, either with a string of host:port, or a
    # http client instance API compatible with Octarine::SimpleHTTP
    # 
    def initialize(host_or_client)
      if host_or_client.respond_to?(:get)
        @client = host_or_client
      else
        @client = Octarine::SimpleHTTP.new(host_or_client)
      end
      @path = ""
    end
    
    # :call-seq: endpoint.call(obj) -> new_endpoint
    # endpoint.(obj) -> new_endpoint
    # 
    # Returns a new endpoint with the string respresentation of obj added to the
    # path. E.g. `endpoint.(123)` will return an endpoint with `/123` appended
    # to the path.
    # 
    def call(id)
      method_missing(id)
    end
    
    # :call-seq: endpoint.method_missing(name, id) -> new_endpoint
    # endpoint.method_missing(name) -> new_endpoint
    # endpoint.anything(id) -> new_endpoint
    # endpoint.anything -> new_endpoint
    # 
    # Implements the path generation DSL.
    #   endpoint.foo(1).bar   #=> new endpoint with path set to /foo/1/bar
    # 
    def method_missing(name, *args)
      super unless args.length <= 1 && !block_given?
      copy = dup
      copy.path = join(copy.path, name.to_s, *args)
      copy
    end
    
    # :call-seq: endpoint.head(id, headers={}) -> response
    # 
    # Make a HEAD request to endpoint's path plus `/id`.
    # 
    def head(id, headers={})
      response = client.head(join(path, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    # :call-seq: endpoint.get(id, headers={}) -> response
    # endpoint[id] -> response
    # 
    # Make a GET request to endpoint's path plus `/id`.
    # 
    def get(id, headers={})
      response = client.get(join(path, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    alias [] get
    
    # :call-seq: endpoint.post(id, body=nil, headers={}) -> response
    # 
    # Make a POST request to endpoint's path plus `/id`.
    # 
    def post(id, body=nil, headers={})
      response = client.post(join(path, id.to_s), body, headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    # :call-seq: endpoint.put(id, body=nil, headers={}) -> response
    # 
    # Make a PUT request to endpoint's path plus `/id`.
    # 
    def put(id, body=nil, headers={})
      response = client.put(join(path, id.to_s), body, headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    # :call-seq: endpoint.delete(id, headers={}) -> response
    # 
    # Make a DELETE request to endpoint's path plus `/id`.
    # 
    def delete(id, headers={})
      response = client.delete(join(path, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    private
    
    def join(*paths)
      paths.map {|path| path.gsub(%r{(^/|/$)}, "")}.join("/")
    end
    
  end
end

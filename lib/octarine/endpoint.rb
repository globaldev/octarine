require "forwardable"
require_relative "simple_http"
require_relative "response"

module Octarine
  class Endpoint
    attr_accessor :url
    protected :url, :url=
    attr_reader :client
    private :client
    
    extend Forwardable
    def_delegators :@client, :host, :port
    
    def initialize(host_or_client)
      if host_or_client.respond_to?(:get)
        @client = host_or_client
      else
        @client = Octarine::SimpleHTTP.new(host_or_client)
      end
      @url = ""
    end
    
    def call(id)
      method_missing(id)
    end
    
    def method_missing(name, *args)
      super unless args.length <= 1 && !block_given?
      copy = dup
      copy.url = join(copy.url, name.to_s, *args)
      copy
    end
    
    def head(id, headers={})
      response = client.head(join(url, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    def get(id, headers={})
      response = client.get(join(url, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    alias [] get
    
    def post(id, body=nil, headers={})
      response = client.post(join(url, id.to_s), body, headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    def put(id, body=nil, headers={})
      response = client.put(join(url, id.to_s), body, headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    def delete(id, headers={})
      response = client.delete(join(url, id.to_s), headers)
      Octarine::Response.new(response.body, response.headers, response.status)
    end
    
    private
    
    def join(*urls)
      urls.map {|url| url.gsub(%r{(^/|/$)}, "")}.join("/")
    end
    
  end
end

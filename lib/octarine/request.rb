require_relative "response"
require_relative "path"
require_relative "simple_http"

module Octarine # :nodoc:
  class Request
    # The Rack enviroment hash
    attr_reader :env
    # The request method, e.g. "GET", "POST"
    attr_reader :method
    # The host name the request was made to
    attr_reader :host
    # The port the request was made to
    attr_reader :port
    # An Octarine::Path representing the path request was made to
    attr_reader :path
    # The request POST/PUT body
    attr_reader :input
    
    # :call-seq: Request.new(env) -> request
    # 
    # Create a Request instance with a Rack enviroment hash.
    # 
    def initialize(env)
      @env = env
      env.delete("router")
      env.delete("router.params")
      template = env.delete("router.route")
      @method = env["REQUEST_METHOD"]
      @host = env["SERVER_NAME"]
      @port = env["SERVER_PORT"]
      path = env["SCRIPT_NAME"] || ""
      path << env["PATH_INFO"] unless env["PATH_INFO"].empty?
      full_path = path.dup
      full_path << "?" << env["QUERY_STRING"] unless env["QUERY_STRING"].empty?
      @path = Path.new(template || path, full_path)
      @input = env["rack.input"]
    end
    
    # :call-seq: request[header_name] -> header_value
    # 
    # Retrieve header.
    #   request["Content-Length"]   #=> "123"
    #   request["Content-Type"]     #=> "application/json"
    # 
    def [](key)
      upper_key = key.to_s.tr("a-z-", "A-Z_")
      unless upper_key == "CONTENT_LENGTH" || upper_key == "CONTENT_TYPE"
        upper_key[0,0] = "HTTP_"
      end
      @env[upper_key]
    end
    
    # :call-seq: request.header -> hash
    # request.headers -> hash
    # 
    # Get header as a hash.
    #   request.header
    #   #=> {"content-length" => "123", "content-type" => "application/json"}
    # 
    def header
      Hash[@env.select do |k,v|
        k =~ /^HTTP_[^(VERSION)]/ || %W{CONTENT_LENGTH CONTENT_TYPE}.include?(k)
      end.map do |key, value|
        [key.sub(/HTTP_/, "").tr("_", "-").downcase, value]
      end]
    end
    alias headers header
    
    # :call-seq: request.to(host) -> response
    # request.to(host, path) -> response
    # request.to(host, path, input) -> response
    # 
    # Re-issue request to new host/path.
    # 
    def to(client, to_path=path, to_input=input)
      client = SimpleHTTP.new(client.to_str) if client.respond_to?(:to_str)
      res = if %W{POST PUT}.include?(method)
        client.__send__(method.downcase, to_path, to_input, header_for_rerequest)
      else
        client.__send__(method.downcase, to_path, header_for_rerequest)
      end
      response_headers = res.headers
      response_headers.delete("transfer-encoding")
      response_headers.delete("content-length")
      Octarine::Response.new(res.body, response_headers, res.status)
    end
    
    def to_s # :nodoc:
      version = " " + @env["HTTP_VERSION"] if @env.key?("HTTP_VERSION")
      "#{method} #{path}#{version}\r\n" << header.map do |key, value|
        key = key.split(/-/).map(&:capitalize).join("-")
        "#{key}: #{value}"
      end.join("\r\n") << "\r\n\r\n"
    end
    
    private
    
    def header_for_rerequest
      head = header
      head.delete("host")
      head
    end
    
  end
end

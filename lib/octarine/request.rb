require_relative "response"
require_relative "endpoint"

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
      path_params = env.delete("router.params")
      @method = env["REQUEST_METHOD"]
      @host = env["SERVER_NAME"]
      @port = env["SERVER_PORT"]
      @path = Path.new(env["SCRIPT_NAME"] || env["PATH_INFO"], path_params,
        env["QUERY_STRING"])
      @input = env["rack.input"]
    end
    
    # :call-seq: request[header_name] -> header_value
    # 
    # Retrieve headers.
    #   request["Content-Length"]   #=> "123"
    #   request["Content-Type"]     #=> "application/json"
    # 
    def [](key)
      upper_key = key.to_s.tr("a-z-", "A-Z_")
      unless upper_key == "CONTENT_LENGTH" || upper_key == "CONTENT_TYPE"
        upper_key[0,0] = "HTTP_"
      end
      @env[key]
    end
    
    # :call-seq: request.to(endpoint) -> response
    # request.to(endpoint, path) -> response
    # request.to(endpoint, path, input) -> response
    # 
    # Re-issue request to new host/path.
    # 
    def to(endpoint=Octarine::Endpoint.new(host), to_path=path, to_input=input)
      res = if %W{POST PUT}.include?(method)
        header = {"content-type" => "application/json"}
        endpoint.send(method.downcase, to_path, to_input, header)
      else
        endpoint.send(method.downcase, to_path)
      end
      headers = res.headers
      headers.delete("transfer-encoding")
      headers.delete("content-length")
      Octarine::Response.new(res.body, headers, res.status)
    end
    
    # :call-seq: request.redirect(path) -> response
    # 
    # Issue redirect to path.
    # 
    def redirect(path)
      
    end
    
    def to_s # :nodoc:
      header = Hash[@env.select do |k,v|
        k =~ /^HTTP_[^(VERSION)]/ || %W{CONTENT_LENGTH CONTENT_TYPE}.include?(k)
      end.map do |key, value|
        [key.sub(/HTTP_/, "").split(/_/).map(&:capitalize).join("-"), value]
      end]
      version = " " + @env["HTTP_VERSION"] if @env.key?("HTTP_VERSION")
      "#{method} #{path}#{version}\r\n" << header.map do |key, value|
        "#{key}: #{value}"
      end.join("\r\n") << "\r\n\r\n"
    end
    
  end
end

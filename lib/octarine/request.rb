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
      full_path = env["SCRIPT_NAME"] || ""
      full_path << env["PATH_INFO"] unless env["PATH_INFO"].empty?
      full_path << "?" << env["QUERY_STRING"] unless env["QUERY_STRING"].empty?
      @path = Path.new(template, full_path)
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
    
    # :call-seq: request.to(host) -> response
    # request.to(host, path) -> response
    # request.to(host, path, input) -> response
    # 
    # Re-issue request to new host/path.
    # 
    def to(client=Octarine::SimpleHTTP.new(host), to_path=path, to_input=input)
      res = if %W{POST PUT}.include?(method)
        header = {"content-type" => "application/json"}
        client.send(method.downcase, to_path, to_input, header)
      else
        client.send(method.downcase, to_path)
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

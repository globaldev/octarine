require_relative "response"
require_relative "endpoint"

module Octarine
  class Request
    attr_reader :env, :method, :host, :port, :path, :input
    
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
    
    def [](key)
      upper_key = key.to_s.tr("a-z-", "A-Z_")
      unless upper_key == "CONTENT_LENGTH" || upper_key == "CONTENT_TYPE"
        upper_key[0,0] = "HTTP_"
      end
      @env[key]
    end
    
    # re-issue request to new host/path
    def to(endpoint=Octarine::Endpoint.new(host), to_path=path, to_input=input)
      res = if %W{POST PUT}.include?(method)
        header = {"content-type" => "application/json"}
        endpoint.send(method.downcase, to_path, to_input, header)
      else
        endpoint.send(method.downcase, to_path)
      end
      headers = res.headers
      headers.delete("transfer-encoding")
      Octarine::Response.new(res.body, headers, res.status)
    end
    
    # issue redirect to path
    def redirect(path)
      
    end
    
    def to_s
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

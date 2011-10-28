require "forwardable"

module Octarine
  class Path
    attr_reader :path_only, :query
    
    extend Forwardable
    def_delegators :@params, :assoc, :[], :each_key, :each_pair,
      :each_value, :empty?, :fetch, :has_key?, :has_value?, :key, :key?, :keys,
      :merge, :rassoc, :to_a, :value?, :values, :values_at,
      *Enumerable.public_instance_methods
    def_delegator :@params, :dup, :to_hash
    def_delegators :@full_path, :+, :=~, :bytesize, :gsub, :length, :size, :sub,
      :to_str, :to_s
    
    def initialize(path_only, params, query_string)
      @path_only = path_only
      params.each do |key, value|
        self.class.class_eval do
          define_method(key) {@params[key]}
        end
      end
      @query_string = query_string
      @query = parse_query(@query_string)
      @full_path = @path_only.dup
      @full_path << "?#{@query_string}" if @query_string && !@query_string.empty?
      @params = params.merge(@query)
    end
    
    def lchomp(separator=$/)
      string = to_s
      string.start_with?(separator) ? string[separator.length..-1] : string
    end
    
    private
    
    def parse_query(string)
      string.split("&").each_with_object({}) do |key_value, out|
        key, value = key_value.split("=")
        key, value = url_decode(key), url_decode(value)
        out[key] = out.key?(key) ? [*out[key]].push(value) : value
      end
    end
    
    def url_decode(str)
      str.tr("+", " ").gsub(/(%[0-9a-f]{2})+/i) {|m| [m.delete("%")].pack("H*")}
    end
  end
end

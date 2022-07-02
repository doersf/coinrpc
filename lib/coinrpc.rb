require "http"
require "oj"
require "json"
require "coinrpc/version"

# let OJ mimic JSON
Oj.mimic_JSON

module CoinRPC
  class Client

    JSONRPC_V1_1 = "1.1".freeze
    JSONRPC_V2_0 = "2.0".freeze
    
    def initialize(url)

      urinfo = URI.parse(url)

      @client = HTTP.persistent("http://#{urinfo.host}:#{urinfo.port}").timeout(60).basic_auth({:user => urinfo.user, :pass => urinfo.password})
      @id = rand(1000000)

    end

    def method_missing(method, *args)

      fixed_method = method.to_s.gsub(/\_/,"").freeze
      post_data = nil
      
      if args[0].is_a?(Array) and args[0].size > 0 then
        # batch request
        post_data = args.map{|arg| {:jsonrpc => JSONRPC_V2_0, :method => fixed_method, :params => arg, :id => (@id += 1)} }
      else
        post_data = {:method => fixed_method, :params => args, :jsonrpc => JSONRPC_V1_1, :id => (@id += 1)}
      end
      
      api_call(post_data)
      
    end

    private
    def api_call(params)

      response = @client.post("/", :body => Oj.dump(params, mode: :compat)).to_s

      # this won"t work without Oj.mimic_JSON
      result = Oj.strict_load(response, :decimal_class => BigDecimal)
      
      raise result["error"]["message"] if result.is_a?(Hash) and !result["error"].nil?

      if result.is_a?(Hash) then
        result["result"]
      else
        # batch call
        result.map{|r| r["result"] || r["error"]}
      end

    end
    
  end

end

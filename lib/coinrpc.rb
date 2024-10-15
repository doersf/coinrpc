require "uri"
require "typhoeus"
require "oj"
require "json"
require "securerandom"
require "coinrpc/version"
require "set"

# let OJ mimic JSON
Oj.mimic_JSON

module CoinRPC

  class TimeoutError < Exception; end
  class UnsuccessfulError < Exception; end
  class NoResponseError < Exception; end
  
  class Client

    JSONRPC_V1_0 = "1.0".freeze
    JSONRPC_V2_0 = "2.0".freeze
    TIMEOUT = 60.freeze
    ENDPOINTS_WITH_ARRAY_ARGS = ['testmempoolaccept'].to_set
    
    def initialize(url)

      urinfo = URI.parse(url)

      @options = {:timeout => TIMEOUT, :userpwd => "#{urinfo.user}:#{urinfo.password}", :headers => {'User-Agent' => "CoinRPC/#{CoinRPC::VERSION}"}}.freeze
      @url = "http://#{urinfo.host}:#{urinfo.port}/".freeze

    end
    
    def random_id
      SecureRandom.hex(4).to_i(16)
    end
    
    def method_missing(method, *args)

      fixed_method = method.to_s.gsub(/\_/, '').freeze
      post_data = nil
      
      if args[0].is_a?(Array) and args[0].size > 0 and !ENDPOINTS_WITH_ARRAY_ARGS.member?(fixed_method) then
        # batch request
        post_data = args.map{|arg| {:jsonrpc => JSONRPC_V2_0, :method => fixed_method, :params => arg, :id => random_id} }
      else
        post_data = {:method => fixed_method, :params => args, :jsonrpc => JSONRPC_V1_0, :id => random_id}
      end
      
      api_call(post_data)
      
    end

    private
    def api_call(params)

      response = Typhoeus::Request.post(@url, :body => Oj.dump(params, :mode => :compat), **@options)

      raise CoinRPC::TimeoutError if response.timed_out?
      raise CoinRPC::NoResponseError if response.code.eql?(0)
      raise CoinRPC::UnsuccessfulError unless response.success?

      # this won't work without Oj.mimic_JSON
      result = Oj.strict_load(response.body, :decimal_class => BigDecimal)
      
      raise result['error']['message'] if result.is_a?(Hash) and !result['error'].nil?

      if result.is_a?(Hash) then
        result['result']
      else
        # batch call
        result.map!{|r| r['result'] || r['error']}
      end

    end
    
  end

end

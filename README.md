# CoinRPC

A simple client for Bitcoin Core style RPC. Supports batch requests.

## Installation

Add this line to your application's Gemfile:

    gem "coinrpc"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coinrpc

## Usage

```
    require "coinrpc"
    client = CoinRPC::Client.new("http://username:password@hostname:port")
    puts client.getblockchaininfo
```

Responses will contain coin values as BigDecimals:

```
    puts client.getrawtransaction(txid)["vout"].first["value"].to_s("F")
```

## Contributing

1. Fork it ( https://github.com/doersf/coinrpc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

# VipnetParser gem

## Summary

VipnetParser may be helpful if you work with ViPNet technology and want to scan string for IDs or parse configuration files like `iplir.conf` and `nodename.doc`.

## Installing

Add this to your Gemfile

`gem "vipnet_parser"`

or just run

`gem install vipnet_parser`

## Usage

### iplir.conf
```
irb(main):001:0> require "vipnet_parser"
=> true
irb(main):002:0> iplirconf_file = File.open("iplir.conf").read
=> "#commentary\n[id]\nid= 0x1a0e000d\nname=...
irb(main):003:0> iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
=> #<VipnetParser::Iplirconf:0x00000001c9ef40 @string="#commentary\n[id]\nid= 0x1a0e000d\nname...
irb(main):004:0> iplirconf.parse()
=> {:id=>{:hash_key=>:id, "0x1a0e000d"=>{:name=>...
irb(main):005:0> iplirconf.hash
=> {:id=>{:hash_key=>:id, "0x1a0e000d"=>{:name=>...
```

Assuming koi8-r encoding of iplir.conf by default. May be overridden like that:

`iplirconf.parse(:hash, "utf8")`

### nodename.doc

```
irb(main):001:0> require "vipnet_parser"
=> true
irb(main):002:0> nodename_file = File.open("nodename.doc").read
=> "administrator                                      1 A 00001A0E00010001 1A0E000B\r\n...
irb(main):003:0> nodename = VipnetParser::Nodename.new(nodename_file)
=> #<VipnetParser::Nodename:0x00000001ed7988...
irb(main):004:0> nodename.parse()
=> {"0x1a0e000b"=>{:name=>...
irb(main):004:0> nodename.hash
=> {"0x1a0e000b"=>{:name=>...
```

Assuming cp866 encoding of nodename.doc by default. May be overridden like that:

`nodename.parse(:hash, "utf8")`

### scan string for ViPNet IDs

```
irb(main):001:0> require "vipnet_parser"
=> true
irb(main):002:0> VipnetParser::id("something 1A0EABCD something")
=> ["0x1a0eabcd"]
irb(main):003:0> VipnetParser::id("0xa0eabcd-0xa0eabcf")
=> ["0x0a0eabcd", "0x0a0eabce", "0x0a0eabcf"]
irb(main):004:0> VipnetParser::id("something 0x1a0eabcd-0x1a0eabcf\nsomething else 0x1a0eabdd")
=> ["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd"]
```
(see more stuff in `spec/vipnet_parser_spec.rb`)

## TODO

* parse `firewall.conf` (for ViPNet Coordinator v3)
* parse `fireaddr.doc`
* parse `channels.doc` along with `nodename.doc` and make nice graph of ViPNet network channels
* more vipneting!

## License

VipnetParser is distributed under the MIT-LICENSE.

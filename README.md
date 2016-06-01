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
irb(main):002:0> content = File.open("iplir.conf").read
=> "#commentary\n[id]\nid= 0x1a0e000d\nname= coordinator...
...
irb(main):003:0> iplirconf = VipnetParser::Iplirconf.new(content)
=> #<VipnetParser::Iplirconf:0x00000001da36c0...
...
irb(main):005:0> iplirconf.sections.class
=> Hash
irb(main):006:0> iplirconf.sections["0x1a0e000a"]
=> {:id=>"0x1a0e000a", :name=>"coordinator1", :filterdefault=>"pass",
:tunnel=>"192.0.2.100-192.0.2.200 to 192.0.2.100-192.0.2.200",
:firewallip=>"192.0.2.4", :port=>"55777",
:proxyid=>"0x00000000", :accessip=>"203.0.113.4",
:usefirewall=>"off", :virtualip=>"198.51.100.4",
:version=>"3.0-670", :ip=>["192.0.2.51", "192.0.2.3"]}
...
```

### nodename.doc

```
irb(main):001:0> require "vipnet_parser"
=> true
irb(main):002:0> content = File.open("nodename.doc").read
=> "administrator                                      1 A 00001A0E00010001 1A0E000B\r\n
...
irb(main):003:0> nodename = VipnetParser::Nodename.new(content)
=> #<VipnetParser::Nodename:0x00000001ed7988...
...
irb(main):004:0> nodename.records.class
=> Hash
irb(main):005:0> nodename.records["0x1a0e000a"]
=> {:name=>"coordinator1", :enabled=>true, :category=>:server,
:server_number=>"0001", :abonent_number=>"0000", :id=>"1A0E000A"}
```

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
* parse `iplir.conf` completely (it's only `[id]` sections for now)
* parse `fireaddr.doc`
* parse `channels.doc` along with `nodename.doc` and make nice graph of ViPNet network channels
* more vipneting!

## License

VipnetParser is distributed under the MIT-LICENSE.

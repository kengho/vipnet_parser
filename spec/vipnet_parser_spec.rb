require_relative "../lib/vipnet_parser"
require_relative "spec_helper"

RSpec.describe VipnetParser do
  describe "iplirconf" do
    content = file_fixture("iplirconf/initial_iplir.conf")

    it "should parse iplirconf" do
      iplirconf = Iplirconf.new(content)
      expected_iplirconf = Iplirconf.new
      expected_iplirconf.content = content
      expected_iplirconf.id = "0x1a0e000d"
      expected_iplirconf.sections = {
        "0x1a0e000d" => {
          :id => "0x1a0e000d",
          :name => "coordinator2",
          :filterdefault => "pass",
          :ip => ["192.0.2.9", "192.0.2.10"],
          :tunnel => "192.0.2.201-192.0.2.202 to 192.0.2.201-192.0.2.202",
          :firewallip => "192.0.2.11",
          :port => "55777",
          :proxyid => "0x00000000",
          :usefirewall => "off",
          :fixfirewall => "off",
          :virtualip => "203.0.113.1",
          :version => "3.0-670",
        },
        "0xffffffff" => {
          :id => "0xffffffff",
          :name => "Encrypted broadcasts",
          :filterdefault => "drop",
          :filterudp => [
            "137, 137, pass, any",
            "138, 138, pass, any",
            "68, 67, pass, any",
            "67, 68, pass, any",
            "2046, 0-65535, pass, recv",
            "2046, 2046, pass, send",
            "2048, 0-65535, pass, recv",
            "2050, 0-65535, pass, recv",
            "2050, 2050, pass, send",
          ],
        },
        "0xfffffffe" => {
          :id => "0xfffffffe",
          :name => "Main Filter",
          :filterdefault => "pass",
        },
        "0x1a0e000b" => {
          :id => "0x1a0e000b",
          :name => "administrator",
          :filterdefault => "pass",
          :ip => ["192.0.2.55"],
          :accessip => "203.0.113.2",
          :firewallip => "192.0.2.6",
          :port => "55777",
          :proxyid => "0xfffffffe",
          :dynamic_timeout => "0",
          :usefirewall => "on",
          :virtualip => "203.0.113.2",
          :version => "3.2-672",
        },
        "0x1a0e000c" => {
          :id => "0x1a0e000c",
          :name => "client1",
          :filterdefault => "pass",
          :ip => ["192.0.2.7"],
          :accessip => "203.0.113.3",
          :firewallip => "192.0.2.8",
          :port => "55777",
          :proxyid => "0xfffffffe",
          :dynamic_timeout => "0",
          :usefirewall => "on",
          :virtualip => "203.0.113.3",
          :version => "0.3-2",
        },
        "0x1a0e000a" => {
          :id => "0x1a0e000a",
          :name => "coordinator1",
          :filterdefault => "pass",
          :ip => ["192.0.2.51", "192.0.2.3"],
          :tunnel => "192.0.2.100-192.0.2.200 to 192.0.2.100-192.0.2.200",
          :firewallip => "192.0.2.4",
          :port => "55777",
          :proxyid => "0x00000000",
          :usefirewall => "off",
          :accessip => "203.0.113.4",
          :virtualip => "198.51.100.4",
          :version => "3.0-670",
        },
      }
      expect(iplirconf).to eq(expected_iplirconf)
    end
  end

  describe "nodename" do
    content = file_fixture("nodename/initial_nodename.doc")

    it "should parse nodename" do
      nodename = Nodename.new(content)
      expected_nodename = Nodename.new
      expected_nodename.content = content
      expected_nodename.records = {
        "1A0E000B" => {
          :name=>"administrator",
          :enabled=>true,
          :category=>:client,
          :server_number=>"0001",
          :abonent_number=>"0001",
          :id=>"1A0E000B",
        },
        "1A0E000C"  =>  {
          :name => "client1-renamed1",
          :enabled => false,
          :category => :client,
          :server_number => "0002",
          :abonent_number => "0001",
          :id => "1A0E000C",
        },
        "1A0E000A" => {
          :name => "coordinator1",
          :enabled => true,
          :category => :server,
          :server_number => "0001",
          :abonent_number => "0000",
          :id => "1A0E000A",
        },
        "1A0E000D" => {
          :name => "coordinator2",
          :enabled => true,
          :category => :server,
          :server_number => "0002",
          :abonent_number => "0000",
          :id => "1A0E000D",
        },
        "1A0E0000" => {
          :name => "Вся сеть",
          :enabled => true,
          :category => :group,
          :server_number => "0000",
          :abonent_number => "0000",
          :id => "1A0E0000",
        },
      }
      expect(nodename).to eq(expected_nodename)
    end
  end

  describe "vipnet id parser" do
    it "should parse '1A0EABCD'" do
      extracted_id = VipnetParser::id("1A0EABCD")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end
    it "should parse 'something 1A0EABCD something'" do
      extracted_id = VipnetParser::id("something 1A0EABCD something")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end
    it "should parse '0xa0eabcd'" do
      extracted_id = VipnetParser::id("0xa0eabcd")
      expect(extracted_id).to eq(["0x0a0eabcd"])
    end
    it "should parse 'something 0xa0eabcd something'" do
      extracted_id = VipnetParser::id("something 0xa0eabcd something")
      expect(extracted_id).to eq(["0x0a0eabcd"])
    end
    it "should parse '0xa0eabcd-0xa0eabcf'" do
      extracted_id = VipnetParser::id("0xa0eabcd-0xa0eabcf")
      expect(extracted_id).to eq(["0x0a0eabcd", "0x0a0eabce", "0x0a0eabcf"])
    end
    it "should return empty array for '0x1a0eabcf-0x1a0eabcd'" do
      extracted_id = VipnetParser::id("0x1a0eabcf-0x1a0eabcd")
      expect(extracted_id).to eq([])
    end
    it "should return one element for '0x1a0eabcd-0x1a0eabcd'" do
      extracted_id = VipnetParser::id("0x1a0eabcd-0x1a0eabcd")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end
    it "should parse 'something 0xa0eabcd-0xa0eabcf something'" do
      extracted_id = VipnetParser::id("something 0xa0eabcd-0xa0eabcf something")
      expect(extracted_id).to eq(["0x0a0eabcd", "0x0a0eabce", "0x0a0eabcf"])
    end
    it "should parse multiline multiid string (easy)" do
      extracted_id = VipnetParser::id("something 0x1a0eabcd-0x1a0eabcf\nsomething else 0x1a0eabdd")
      expect(extracted_id).to eq(["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd"].sort)
    end
    it "should parse multiline multiid string (hard)" do
      extracted_id = VipnetParser::id("something 0x1a0eabcd-0x1a0eabcf\nsomething else 0x1a0eabdd\n and more 1A0F0001")
      expect(extracted_id).to eq(["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd", "0x1a0f0001"].sort)
    end
    it "should parse multiline multiid string (nightmare)" do
      extracted_id = VipnetParser::id(
        "I would like to thank 0x1a0eabcd-0x1a0eabcf"\
        "also 0x1a0eabdd and"\
        "also 0x1a0eabd0-0x1a0eabd0 and"\
        "and last but not least 1A0F0001, which is my favourite"\
        "forgot about 0xabcd"\
        ""
      )
      expect(extracted_id).to eq(["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd", "0x1a0eabd0", "0x1a0f0001", "0x0000abcd"].sort)
    end
    it "shouldn't parse beyond some threshold" do
      extracted_id = VipnetParser::id({ string: "0x0000-0xffff", threshold: "0xffff".to_i(16) })
      expect(extracted_id).to eq([])
    end
  end

  describe "network parser" do
    it "should parse '0x1a0eabcd' " do
      extracted_network = VipnetParser::network("0x1a0eabcd")
      expect(extracted_network).to eq("6670")
    end
  end
end

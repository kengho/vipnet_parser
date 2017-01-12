require "spec_helper"

describe VipnetParser do
  describe "vipnet id parser" do
    it "should get vipnet ids from strings like '1a0eabcd'" do
      extracted_id = VipnetParser::id("1a0eabcd")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end

    it "should get vipnet ids from strings like '1A0EABCD'" do
      extracted_id = VipnetParser::id("1A0EABCD")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end

    it "should get vipnet ids from strings like 'something 1A0EABCD something'" do
      extracted_id = VipnetParser::id("something 1A0EABCD something")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end

    it "should get vipnet ids from strings like '0xa0eabcd'" do
      extracted_id = VipnetParser::id("0xa0eabcd")
      expect(extracted_id).to eq(["0x0a0eabcd"])
    end

    it "should get vipnet ids from strings like 'something 0xa0eabcd something'" do
      extracted_id = VipnetParser::id("something 0xa0eabcd something")
      expect(extracted_id).to eq(["0x0a0eabcd"])
    end

    it "should get vipnet ids from strings like '0xa0eabcd-0xa0eabcf'" do
      extracted_id = VipnetParser::id("0xa0eabcd-0xa0eabcf")
      expect(extracted_id).to eq(["0x0a0eabcd", "0x0a0eabce", "0x0a0eabcf"])
    end

    it "should return empty array while gettings vipent ids from strings like '0x1a0eabcf-0x1a0eabcd'" do
      extracted_id = VipnetParser::id("0x1a0eabcf-0x1a0eabcd")
      expect(extracted_id).to eq([])
    end

    it "should return one element while gettings vipent ids from strings like '0x1a0eabcd-0x1a0eabcd'" do
      extracted_id = VipnetParser::id("0x1a0eabcd-0x1a0eabcd")
      expect(extracted_id).to eq(["0x1a0eabcd"])
    end

    it "should get vipnet ids from strings like 'something 0xa0eabcd-0xa0eabcf something'" do
      extracted_id = VipnetParser::id("something 0xa0eabcd-0xa0eabcf something")
      expect(extracted_id).to eq(["0x0a0eabcd", "0x0a0eabce", "0x0a0eabcf"])
    end

    it "should get vipnet ids from multiline multiid string (easy)" do
      extracted_id = VipnetParser::id("something 0x1a0eabcd-0x1a0eabcf\nsomething else 0x1a0eabdd")
      expect(extracted_id).to eq(["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd"].sort)
    end

    it "should get vipnet ids from multiline multiid string (hard)" do
      extracted_id = VipnetParser::id("something 0x1a0eabcd-0x1a0eabcf\nsomething else 0x1a0eabdd\n and more 1A0F0001")
      expect(extracted_id).to eq(["0x1a0eabcd", "0x1a0eabce", "0x1a0eabcf", "0x1a0eabdd", "0x1a0f0001"].sort)
    end

    it "should get vipnet ids from multiline multiid string (nightmare)" do
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

    it "shouldn't get vipnet ids from strings beyond specified threshold" do
      extracted_id = VipnetParser::id({ string: "0x0000-0xffff", threshold: "0xffff".to_i(16) })
      expect(extracted_id).to eq([])
    end

    it "should get vipnet ids from strings with cyrillic symbols" do
      extracted_id = VipnetParser::id("1АБЕСДЕФ")
      expect(extracted_id).to eq(["0x1abecdef"])
    end

    it "should get network id from vipent id" do
      extracted_network = VipnetParser::network("0x1a0eabcd")
      expect(extracted_network).to eq("6670")
    end

    it "should reject network_vid from name" do
      normal_name1 = VipnetParser::name("client1                                       6671", "0x1a0f000d")
      expect(normal_name1).to eq("client1")
    end

    it "shouldn't reject anything if length of name is < 50" do
      normal_name1 = VipnetParser::name("client1                                       667", "0x1a0f000d")
      expect(normal_name1).to eq("client1                                       667")
    end

    it "shouldn't reject anything if the ending of name is not correct network_vid" do
      normal_name1 = VipnetParser::name("client1                                       6670", "0x1a0f000d")
      expect(normal_name1).to eq("client1                                       6670")
    end
  end
end

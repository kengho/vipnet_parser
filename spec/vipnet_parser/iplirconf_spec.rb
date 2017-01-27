require "spec_helper"

describe VipnetParser do
  it "should parse iplirconf", ispec00: true do
    iplirconf_file = file_fixture("iplirconf/iplir01.conf")
    expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf01.yml")
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end

  it "should parse iplirconf (normalize names)", ispec01: true do
    iplirconf_file = file_fixture("iplirconf/iplir02.conf")
    expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf02.yml")
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse(normalize_names: true)
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end

  it "should parse iplirconf (HW 4)", ispec02: true do
    iplirconf_file = file_fixture("iplirconf/iplir03.conf")
    expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf03.yml")
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse(normalize_names: true)
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end

  it "should get version of iplirconf", ispec03: true do
    iplirconf_file1 = file_fixture("iplirconf/iplir01.conf")
    iplirconf_file3 = file_fixture("iplirconf/iplir03.conf")
    iplirconf1 = VipnetParser::Iplirconf.new(iplirconf_file1)
    iplirconf3 = VipnetParser::Iplirconf.new(iplirconf_file3)
    expect(iplirconf1.version).to eq("3.x")
    expect(iplirconf3.version).to eq("4.2.3-3")
  end

  it "should downgrade 4.2.x to 3.x", ispec04: true do
    iplirconf_file3_x = file_fixture("iplirconf/iplir02.conf")
    iplirconf_file4_2 = file_fixture("iplirconf/iplir03.conf")
    iplirconf3_x = VipnetParser::Iplirconf.new(iplirconf_file3_x)
    iplirconf3_x.parse
    iplirconf4_2 = VipnetParser::Iplirconf.new(iplirconf_file4_2)
    iplirconf4_2.parse
    iplirconf4_2.downgrade("3.x")
    expect(iplirconf4_2.hash).to eq(iplirconf3_x.hash)
  end

  # TODO downgrade checks tests (after complete downgrade implementation).
end

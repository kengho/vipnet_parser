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
    actual_iplirconf1 = VipnetParser::Iplirconf.new(iplirconf_file1)
    actual_iplirconf3 = VipnetParser::Iplirconf.new(iplirconf_file3)
    expect(actual_iplirconf1.version).to eq("3")
    expect(actual_iplirconf3.version).to eq("4")
  end
end

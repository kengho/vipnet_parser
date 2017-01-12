require "spec_helper"

describe VipnetParser do
  it "should parse iplirconf" do
    iplirconf_file = file_fixture("iplirconf/iplir01.conf")
    expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf01.yml")
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse()
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end

  it "should parse iplirconf (normalize names)" do
    iplirconf_file = file_fixture("iplirconf/iplir02.conf")
    expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf02.yml")
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse({ normalize_names: true })
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end
end

require "spec_helper"

describe VipnetParser do
  require "yaml"
  iplirconf_file = file_fixture("iplirconf/iplir.conf")
  expected_iplirconf_hash = yaml_fixture("iplirconf/iplirconf.yml")

  it "should parse iplirconf" do
    actual_iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    actual_iplirconf.parse(:hash)
    expect(actual_iplirconf.hash).to eq(expected_iplirconf_hash)
  end
end

require "spec_helper"

describe VipnetParser do
  it "should parse nodename", nspec00: true do
    nodename_file = file_fixture("nodename/nodename01.doc")
    expected_nodename_hash = yaml_fixture("nodename/nodename01.yml")
    actual_nodename = VipnetParser::Nodename.new(nodename_file)
    actual_nodename.parse
    expect(actual_nodename.hash).to eq(expected_nodename_hash)
  end

  it "should parse nodename (normalize names)", nspec01: true do
    nodename_file = file_fixture("nodename/nodename02.doc")
    expected_nodename_hash = yaml_fixture("nodename/nodename02.yml")
    actual_nodename = VipnetParser::Nodename.new(nodename_file)
    actual_nodename.parse(normalize_names: true)
    expect(actual_nodename.hash).to eq(expected_nodename_hash)
  end
end

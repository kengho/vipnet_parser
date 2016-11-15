require "spec_helper"

describe VipnetParser do
  nodename_file = file_fixture("nodename/nodename.doc")
  expected_nodename_hash = yaml_fixture("nodename/nodename.yml")

  it "should parse nodename" do
    actual_nodename = VipnetParser::Nodename.new(nodename_file)
    actual_nodename.parse(:hash)
    expect(actual_nodename.hash).to eq(expected_nodename_hash)
  end
end

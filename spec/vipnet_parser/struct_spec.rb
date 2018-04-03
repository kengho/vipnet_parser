require "spec_helper"

describe VipnetParser do
  it "should convert struct.rep into hash", ispec00: true do
    struct_file = file_fixture("struct/struct1.rep")
    expected_struct_hash = yaml_fixture("struct/struct1.yml")
    actual_struct = VipnetParser::Struct.new(struct_file)
    actual_struct.parse
    expect(actual_struct.hash).to eq(expected_struct_hash)
  end
end

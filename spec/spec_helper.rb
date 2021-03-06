require "vipnet_parser"

# https://github.com/jnunemaker/httparty/blob/master/spec/spec_helper.rb
def file_fixture(filename)
  open(File.join(File.dirname(__FILE__), 'fixtures', "#{filename}")).read
end

def yaml_fixture(filename)
  require "yaml"
  YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures', "#{filename}"))
end

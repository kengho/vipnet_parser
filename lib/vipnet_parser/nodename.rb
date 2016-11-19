require "vipnet_parser/vipnet_config"

module VipnetParser
  class Nodename < VipnetConfig
    attr_accessor :string, :hash

    def initialize(nodename_file)
      @string = nodename_file
    end

    def parse(format = :hash, encoding = "cp866")
      # change encoding to utf8
      string = self.string
        .force_encoding(encoding)
        .encode("utf-8", replace: nil)

      case format
      when :hash
        @hash = {}

        string.split("\r\n").each do |line|
          record = _record_hash(line)
          record[:name].rstrip!
          record[:enabled] = { "1" => true, "0" => false }[record[:enabled]]
          record[:category] = { "A" => :client, "S" => :server, "G" => :group }[record[:category]]
          normal_id = VipnetParser::id(record[:id]).first
          record.delete(:id)
          @hash[normal_id] = record
        end
      end
    end

    def _record_hash(line)
      record_regexp = /^
        (?<name>.{50})\s
        (?<enabled>[01])\s
        (?<category>[ASG])\s
        [0-9A-F]{8}
        (?<server_number>[0-9A-F]{4})
        (?<abonent_number>[0-9A-F]{4})\s
        (?<id>[0-9A-F]{8})
      $/x
      match = record_regexp.match(line)
      names = match.names.map { |name| name.to_sym }

      # https://gist.github.com/flarnie/6221219
      return Hash[names.zip(match.captures)]
    end

    private :_record_hash
  end
end

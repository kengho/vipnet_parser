require "vipnet_parser/vipnet_config"

module VipnetParser
  class Nodename < VipnetConfig
    attr_accessor :string, :hash

    DEFAULT_PARSE_ARGS = {
      format: :hash,
      encoding: "cp866",
      normalize_names: false,
    }

    def parse(args = DEFAULT_PARSE_ARGS)
      args = DEFAULT_PARSE_ARGS.merge(args)
      format, encoding, normalize_names = args.values_at(
        :format, :encoding, :normalize_names,
      )

      # Change encoding to utf8.
      string = self.string
        .force_encoding(encoding)
        .encode("utf-8", replace: nil)

      enable_aliases = { "1" => true, "0" => false }
      group_aliases = { "A" => :client, "S" => :server, "G" => :group }

      case format
      when :hash
        @hash = { _meta: { version: "3" }, id: {} }

        string.split("\r\n").each do |line|
          record = _record_hash(line)
          record[:name].rstrip!
          record[:enabled] = enable_aliases[record[:enabled]]
          record[:category] = group_aliases[record[:category]]
          normal_id = VipnetParser.id(record[:id]).first
          if normalize_names
            record[:name] = VipnetParser.name(record[:name], normal_id)
          end
          record.delete(:id)
          @hash[:id][normal_id] = record
        end

        @hash
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
      Hash[names.zip(match.captures)]
    end

    private :_record_hash
  end
end

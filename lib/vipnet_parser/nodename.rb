require "vipnet_parser/vipnet_config"

module VipnetParser
  class Nodename < VipnetConfig
    PROPS = [:content, :records]
    attr_accessor *PROPS, :last_error
    private_constant :PROPS

    def initialize(*args)
      @props = PROPS
      unless args.size == 1
        return false
      end
      @content = args[0]
      lines = content.force_encoding("cp866").encode("utf-8", replace: nil).split("\r\n")
      if lines.size == 0
        @last_error = "error parsing nodename"
        return false
      end
      @records = Hash.new
      lines.each do |line|
        tmp_record = Hash.new
        tmp_record = get_record_params(line)
        tmp_record[:name].rstrip!
        tmp_record[:enabled] = { "1" => true, "0" => false }[tmp_record[:enabled]]
        tmp_record[:category] = { "A" => :client, "S" => :server, "G" => :group }[tmp_record[:category]]
        @records[VipnetParser::id(tmp_record[:id])[0]] = tmp_record.reject { |k, _| k == :id }
      end
      true
    end

    def get_record_params(line)
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

    private :get_record_params
  end
end

class VipnetParser
  def ==(other)
    res = true
    @props.each do |prop|
      res = res && self.send(prop.to_s) == other.send(prop.to_s)
    end
    res
  end

  def self.id(args)
    if args.class == String
      string = args
      array = Array.new
    elsif args.class == Hash
      string = args[:string]
      array = args[:array]
      threshold = args[:threshold]
    end
    array = [] unless array
    regexps = {
      /(.*)(0x[0-9a-f]{1,8}-0x[0-9a-f]{1,8})(.*)/m => method(:id_parse_variant1),
      /(.*)([0-9A-F]{8})(.*)/m => method(:id_parse_variant2),
      /(.*)0x([0-9a-f]{1,8})(.*)/m => method(:id_parse_variant3),
    }
    string_matches_anything = false
    regexps.each do |regexp, callback|
      if string =~ regexp && !string_matches_anything
        string_matches_anything = true
        array += callback.call({ string: Regexp.last_match(2), threshold: threshold })
        if Regexp.last_match(1) != ""
          array += VipnetParser::id({ string: Regexp.last_match(1), array: array, threshold: threshold })
        end
        if Regexp.last_match(3) != ""
          array += VipnetParser::id({ string: Regexp.last_match(3), array: array, threshold: threshold })
        end
      end
    end
    if string_matches_anything
      return array.uniq.sort
    else
      return []
    end
  end

  def self.id_parse_variant1(args)
    string = args[:string]
    threshold = args[:threshold]
    string =~ /0x([0-9a-f]{1,8})-0x([0-9a-f]{1,8})/
    interval_begin = Regexp.last_match(1).to_i(16)
    interval_end = Regexp.last_match(2).to_i(16)
    return [] if interval_end < interval_begin
    if threshold
      return [] if interval_end - interval_begin + 1 > threshold
    end
    array = Array.new
    (interval_end - interval_begin + 1).times do |n|
      array.push("0x#{(interval_begin + n).to_s(16).rjust(8, '0')}")
    end
    array
  end

  def self.id_parse_variant2(args)
    string = args[:string]
    ["0x" + string.downcase]
  end

  def self.id_parse_variant3(args)
    string = args[:string]
    ["0x" + string.rjust(8, "0")]
  end

  def self.network(id)
    normal_ids = id(id)
    if normal_ids
      normal_id = normal_ids[0]
      return id[2..5].to_i(16).to_s(10)
    end
    false
  end

  private_class_method :id_parse_variant1, :id_parse_variant2, :id_parse_variant3
end

class Iplirconf < VipnetParser
  PROPS = [:content, :id, :sections]
  attr_accessor *PROPS, :last_error
  private_constant :PROPS

  def initialize(*args)
    @props = PROPS
    unless args.size == 1
      return false
    end
    @content = args[0]
    # remove comments
    content_nc = @content.gsub(/^#.*\n/, "")
    # remove ending
    @sections = Hash.new
    adapter_position = content_nc.index("[adapter]")
    unless adapter_position
      @last_error = "unable to parse iplirconf (no [adapter] section)"
      return false
    end
    # prepare for split
    content_nc = content_nc[0..(adapter_position - 2)]
    content_nc = "\n" + content_nc
    content_nc.split("\n[id]\n").reject{ |t| t.empty? }.each_with_index do |section_content, i|
      tmp_section = Hash.new
      props = {
        :single => [
          :id, :name, :filterdefault, :tunnel,
          :firewallip, :port, :proxyid, :dynamic_timeout, :accessip,
          :usefirewall, :fixfirewall, :virtualip, :version,
        ],
        :multi => [:ip, :filterudp, :filtertcp]
      }
      props.each do |type, props|
        props.each do |prop|
          get_section_param({ prop: prop, section: tmp_section, content: section_content, type: type })
        end
      end
      # self section id
      @id = tmp_section[:id] if i == 0
      @sections[tmp_section[:id]] = tmp_section
    end
    true
  end

  def get_section_param(args)
    value_regexp = Regexp.new("^#{args[:prop].to_s}=\s(.*)$")
    if args[:type] == :multi
      tmp_array = Array.new
      args[:content].each_line do |line|
        value = line[value_regexp, 1]
        tmp_array.push(value) if value
      end
      args[:section][args[:prop]] = tmp_array unless tmp_array.empty?
    elsif args[:type] == :single
      value = args[:content][value_regexp, 1]
      args[:section][args[:prop]] = value if value
    end
  end

  private :get_section_param
end

class Nodename < VipnetParser
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
      @records[tmp_record[:id]] = tmp_record
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

require "vipnet_parser/vipnet_config"

module VipnetParser
  class Iplirconf < VipnetConfig
    PROPS = [:content, :id, :sections]
    attr_accessor *PROPS, :last_error
    private_constant :PROPS

    def initialize(*args)
      @props = PROPS
      unless args.size == 1
        return false
      end
      args = args[0]
      if args.class == String
        @content = args
      elsif args.class == Hash
        @content = args[:content]
      end
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
            get_section_param({ prop: prop, section: tmp_section, content: section_content, type: type, opts: args })
          end
        end
        # self section id
        @id = tmp_section[:id] if i == 0
        @sections[tmp_section[:id]] = tmp_section
      end
      true
    end

    def get_section_param(args)
      opts = {} if args[:opts].class == String
      opts = args[:opts] if args[:opts].class == Hash
      value_regexp = Regexp.new("^#{args[:prop].to_s}=\s(.*)$")
      if args[:type] == :multi
        tmp_array = Array.new
        args[:content].each_line do |line|
          value = line[value_regexp, 1]
          tmp_array.push(value) if value
        end
        unless tmp_array.empty?
          tmp_array = tmp_array.to_s if opts[:arrays_to_s]
          args[:section][args[:prop]] = tmp_array
        end
      elsif args[:type] == :single
        value = args[:content][value_regexp, 1]
        args[:section][args[:prop]] = value if value
      end
    end

    private :get_section_param
  end
end

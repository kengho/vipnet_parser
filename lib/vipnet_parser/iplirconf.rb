require "vipnet_parser/vipnet_config"

module VipnetParser
  class Iplirconf < VipnetConfig
    attr_accessor :string, :hash

    def initialize(iplirconf_file)
      @string = iplirconf_file
    end

    DEFAULT_PARSE_ARGS = {
      format: :hash,
      encoding: "koi8-r",
      normalize_names: false,
    }

    def parse(args = DEFAULT_PARSE_ARGS)
      args = DEFAULT_PARSE_ARGS.merge(args)
      format, encoding, normalize_names = args.values_at(
        :format, :encoding, :normalize_names,
      )

      # Change encoding to utf8 and remove comments.
      string = self.string
                   .force_encoding(encoding)
                   .encode("utf-8")
                   .gsub(/^#.*\n/, "")
                   .gsub(/^;.*\n/, "")

      # "[id]something[server]something".split(/(?=\[.+\])/)
      # =>
      # ["[id]something", "[server]something"]
      string = string.split(/(?=\[.+\])/)

      # ["[id]something1", "[server]something2"]
      # =>
      # [
      #   { name: :id, content: "something1" },
      #   { name: :server, content: "something2" },
      # ]
      sections = string.map do |section|
        section =~ /\[(?<section_name>.+)\]\n(?<section_content>.*)/m
        {
          name: Regexp.last_match(:section_name).to_sym,
          content: Regexp.last_match(:section_content),
        }
      end

      case format
      when :hash
        @hash = {}
        hash_keys = {
          id: :id,
          adapter: :name,
        }

        sections.each do |section|
          @hash[section[:name]] ||= {}
          hash_key = hash_keys[section[:name]]
          if hash_key
            hash, current_key = _section_hash(section[:content], hash_key)
            @hash[section[:name]][current_key] = hash

            # Normalize names.
            # (Only available for [id] sections, which are processed with current_key == id.)
            name = @hash[section[:name]][current_key][:name]
            next unless name && normalize_names
            name = VipnetParser.name(name, current_key)
            @hash[section[:name]][current_key][:name] = name
          else
            hash, _ = _section_hash(section[:content])
            @hash[section[:name]] = hash
          end
        end

        # Reduce [servers] section.
        # :servers => { :server => ["0x1a0e000a, coordinator1"] }
        # =>
        # :servers => ["0x1a0e000a, coordinator1"]
        @hash[:servers] = @hash[:servers][:server] || nil

        @hash
      end
    end

    # Returns config version.
    def version
      self.parse(format: :hash) unless self.hash
      config_version = self.hash[:misc][:config_version]
      parsed_config_version = if config_version
                                config_version
                              else
                                "3.x"
                              end

      parsed_config_version
    end

    def _section_hash(section_content, hash_key = nil)
      hash = {}

      section_content.split("\n").each do |line|
        if line =~ /(?<prop>.*)=\s(?<value>.*)/
          prop = Regexp.last_match(:prop).to_sym
          value = Regexp.last_match(:value)

          array_props = %i(
            ip filterudp filtertcp server
            exclude_from_tunnels accessiplist subnet_real subnet_virtual
          )
          if array_props.include?(prop)
            if hash[prop]
              hash[prop].push(value)
            else
              hash[prop] = [value]
            end
          else
            hash[prop] = value
          end
        end
      end

      return hash unless hash_key && hash[hash_key]
      current_key = hash[hash_key]
      hash.delete(hash_key)

      [hash, current_key]
    end

    private :_section_hash
  end
end

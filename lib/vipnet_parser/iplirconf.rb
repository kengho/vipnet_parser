require "vipnet_parser/vipnet_config"

module VipnetParser
  class Iplirconf < VipnetConfig
    attr_accessor :string, :hash

    def initialize(iplirconf_file)
      @string = iplirconf_file
    end

    DEFAULT_PARSE_ARGS = { format: :hash, encoding: "koi8-r", normalize_names: false }

    def parse(args = DEFAULT_PARSE_ARGS)
      args = DEFAULT_PARSE_ARGS.merge(args)
      format, encoding, normalize_names = args.values_at(:format, :encoding, :normalize_names)

      # change encoding to utf8 and remove comments
      string = self.string
        .force_encoding(encoding)
        .encode("utf-8")
        .gsub(/^#.*\n/, "")
        .gsub(/^;.*\n/, "")

      # "[id]something[server]something".split(/(?=\[.+\])/)
      # => ["[id]something", "[server]something"]
      string = string.split(/(?=\[.+\])/)

      # ["[id]something1", "[server]something2"]
      # => [
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
        @hash = { _meta: { version: "3" }}
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

            # normalize names
            # (only available for [id] sections, which are processed with current_key == id)
            name = @hash[section[:name]][current_key][:name]
            if name && normalize_names
              @hash[section[:name]][current_key][:name] = VipnetParser.name(name, current_key)
            end
          else
            hash, _ = _section_hash(section[:content])
            @hash[section[:name]] = hash
          end
        end

        # :servers => { :server => ["0x1a0e000a, coordinator1"] }
        # => :servers => ["0x1a0e000a, coordinator1"]
        @hash[:servers] = @hash[:servers][:server] || nil

        return @hash
      end
    end

    def _section_hash(section_content, hash_key = nil)
      hash = {}

      section_content.split("\n").each do |line|
        if line =~ /(?<prop>.*)=\s(?<value>.*)/
          prop = Regexp.last_match(:prop).to_sym
          value = Regexp.last_match(:value)

          # array-type props
          if %i[ip filterudp filtertcp server].include?(prop)
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

      if hash_key && hash[hash_key]
        current_key = hash[hash_key]
        hash.delete(hash_key)
        return [hash, current_key]
      else
        return hash
      end
    end

    private :_section_hash
  end
end

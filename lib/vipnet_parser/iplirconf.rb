require "vipnet_parser/vipnet_config"

module VipnetParser
  class Iplirconf < VipnetConfig
    attr_accessor :string, :hash

    def initialize(iplirconf_file)
      @string = iplirconf_file
    end

    def parse(format = :hash)
      # remove comments
      string = self.string
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
          name: Regexp.last_match[:section_name].to_sym,
          content: Regexp.last_match[:section_content],
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
            @hash[section[:name]][:hash_key] ||= hash_key
            hash, current_key = _section_hash(section[:content], hash_key)
            @hash[section[:name]][current_key] = hash
          else
            hash, _ = _section_hash(section[:content])
            @hash[section[:name]] = hash
          end
        end

        # :servers => { :server => ["0x1a0e000a, coordinator1"] }
        # => :servers => ["0x1a0e000a, coordinator1"]
        @hash[:servers] = @hash[:servers][:server] || nil
      end

    end

    def _section_hash(section_content, hash_key = nil)
      hash = {}

      section_content.split("\n").each do |line|
        if line =~ /(?<prop>.*)=\s(?<value>.*)/
          prop = Regexp.last_match[:prop].to_sym
          value = Regexp.last_match[:value]

          # array-type props
          if [:ip, :filterudp, :filtertcp, :server].include?(prop)
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

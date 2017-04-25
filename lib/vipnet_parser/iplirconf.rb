require "vipnet_parser/vipnet_config"

module VipnetParser
  class Iplirconf < VipnetConfig
    attr_accessor :string, :hash, :version

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

      unless self.string
        case format
        when :hash
          @hash = {}
          return
        end
      end

      # Change encoding to utf8 and remove comments.
      string = self.string
                   .force_encoding(encoding)
                   .encode("utf-8")
                   .gsub(/^#.*\n/, "")
                   .gsub(/^;.*\n/, "")

      # "[id]something[server]something".split(/(?=\[.+\])/)
      # =>
      # ["[id]something", "[server]something"]
      string = string.split(/^(?=\[.+\])/)

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
        @hash[:servers] = @hash[:servers][:server] || nil unless @hash.empty?

        _calculate_version

        @hash
      end
    end

    def downgrade(to)
      # TODO: downgrade string too (need rebuild() first).
      return false unless @hash
      version = self.version
      version =~ /^(?<minor_version>\d\.\d)\.*/
      return false unless Regexp.last_match
      minor_version = Regexp.last_match(:minor_version)

      case to
      when "3.x"
        case minor_version
        when "4.2"
          new_hash = @hash.clone
          props_to_delete = {
            id: { any: %i(exclude_from_tunnels accessiplist) },
            visibility: %i(tunneldefault subnet_real subnet_virtual),
            misc: %i(
              config_version timesync tunnel_local_network
              ompnumthreads tcptunnel_establish tunnel_virt_assignment
            ),
          }
          props_to_add = {
            misc: [{ iparponly: "off" }],
          }

          @hash.each_key do |key|
            # { a: 1, b: 2 }.map(&:first)
            # =>
            # [:a, :b]
            next unless props_to_delete.map(&:first).include?(key)
            props = props_to_delete[key]

            # Delete new props.
            hashes_to_delete = []
            case props

            # "id" key.
            when Hash
              props = props.values.first
              subkeys = @hash[key].map(&:first)
              subkeys.each do |subkey|
                props.each do |prop|
                  hashes_to_delete.push([new_hash[key][subkey], prop])
                end
              end
            else
              props.each do |prop|
                hashes_to_delete.push([new_hash[key], prop])
              end
            end
            hashes_to_delete.each { |hash| hash.first.delete(hash.last) }
          end

          # Add default values of deprecated props.
          props_to_add.each do |key, props|
            props.each do |prop|
              new_hash[key].merge!(prop)
            end
          end

          # Move to old "ip" style.
          new_hash[:id].each_key do |id|
            next unless new_hash[:id][id][:ip]
            new_hash[:id][id][:ip].each_with_index do |ip, i|
              ip =~ /^(?<ip>.+),\s(?<accessip>.+)/
              next unless Regexp.last_match
              new_hash[:id][id][:ip][i] = Regexp.last_match(:ip)
            end
          end

          @hash = new_hash

          true
        else
          false
        end
      else
        false
      end
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

    def _calculate_version
      config_version = self.hash[:misc][:config_version]
      parsed_config_version = if config_version
                                config_version
                              else
                                "3.x"
                              end

      @version = parsed_config_version
    end

    private :_section_hash, :_calculate_version
  end
end

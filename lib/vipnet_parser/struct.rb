require "vipnet_parser/vipnet_config"

module VipnetParser
  class Struct < VipnetConfig
    attr_accessor :string, :hash

    DEFAULT_PARSE_ARGS = {
      format: :hash,
      encoding: "cp866",
    }

    def parse(args = DEFAULT_PARSE_ARGS)
      args = DEFAULT_PARSE_ARGS.merge(args)
      format, encoding = args.values_at(
        :format, :encoding, :normalize_names,
      )

      # Change encoding to utf8.
      string = self.string
        .force_encoding(encoding)
        .encode("utf-8", replace: nil)

      sign_aliases = { "+" => true, "-" => false }

      case format
      when :hash
        @hash = { nodes: [] }

        current_node_id = nil
        previous_node = nil
        current_usergroups = []
        current_users = []
        lines = string.split("\r\n")
        lines.each_with_index do |line, line_index|
          line_hash = _line_hash(line)
          next unless line_hash

          # Normalize data.
          line_hash.each do |_, higher_name_hash|
            next unless higher_name_hash.class == Hash

            parsed_ids = VipnetParser.id(higher_name_hash[:id])
            id =
              if parsed_ids.size > 0
                parsed_ids.first
              else
                nil
              end
            higher_name_hash[:id] = id

            higher_name_hash[:name].rstrip!
            if higher_name_hash[:name].size == 0
              higher_name_hash[:name] = nil
            end
          end
          line_hash[:node][:network_address].rstrip!
          line_hash[:user][:sign] = sign_aliases[line_hash[:user][:sign]]
          line_hash[:usergroup] = nil if (!line_hash[:usergroup][:id] && !line_hash[:usergroup][:name])

          # first id
          if !current_node_id && line_hash[:node][:id]
            current_node_id = line_hash[:node][:id]
          end

          # initial previous node
          if !previous_node
            previous_node = line_hash[:node]
          end

          next_node_appears = (line_hash[:node][:id] && current_node_id != line_hash[:node][:id])
          this_is_the_last_line = (line_index == lines.size - 1)

          if this_is_the_last_line
            current_usergroups.push(line_hash[:usergroup]) if line_hash[:usergroup]
            current_users.push(line_hash[:user])
          end

          if next_node_appears || this_is_the_last_line
            final_hash = previous_node
            final_hash[:usergroups] = current_usergroups.dup
            final_hash[:users] = current_users.dup
            @hash[:nodes].push(final_hash)
          end

          if next_node_appears
            current_node_id = line_hash[:node][:id]
            previous_node = line_hash[:node]
            current_usergroups = []
            current_users = []
          end

          current_usergroups.push(line_hash[:usergroup]) if line_hash[:usergroup]
          current_users.push(line_hash[:user])
        end

        @hash
      end
    end

    def _line_hash(line)
      # NOTE: could be done without regexp, but it seems easier with.
      line_regexp = /^
        (?<node>.{#{15 + 1 + 50 + 1 + 8}})│
        (?<usergroup>.{#{50 + 1 + 8}})│
        (?<user>.{#{56 + 1 + 8 + 1 + 1}})
      $/x
      node_regexp = /(?<network_address>.{15})│(?<name>.{50})│(?<id>.{8})/
      usergroup_regexp = /(?<name>.{50})│(?<id>.{8})/
      user_regexp = /(?<name>.{56})│(?<id>.{8})│(?<sign>.{1})/
      regexps_map = {
        node: node_regexp,
        usergroup: usergroup_regexp,
        user: user_regexp,
      }

      line_match = line_regexp.match(line)
      return unless line_match
      line_names = line_match.names.map { |name| name.to_sym }
      line_hash = Hash[line_names.zip(line_match.captures)]

      hash = {}
      regexps_map.each do |higher_name_component, regexp|
        match = regexp.match(line_hash[higher_name_component])
        next unless match
        names = match.names.map { |name| name.to_sym }
        higher_name_hash = Hash[names.zip(match.captures)]

        hash[higher_name_component] = higher_name_hash
      end

      hash
    end

    private :_line_hash
  end
end

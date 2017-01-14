module VipnetParser
  def id(args)
    if args.class == String
      string = args
      array = []
    elsif args.class == Hash
      string, array, threshold = args.values_at(:string, :array, :threshold)
    end
    string = string.downcase
    cyrillic_sub = {
      "а" => "a", "б" => "b", "с" => "c", "д" => "d", "е" => "e", "ф" => "f",
      "А" => "a", "Б" => "b", "С" => "c", "Д" => "d", "Е" => "e", "Ф" => "f",
    }
    cyrillic_sub.each do |cyr, lat|
      string = string.gsub(cyr, lat)
    end

    array = [] unless array
    regexps = {
      /(.*)(0x[0-9a-f]{1,8}-0x[0-9a-f]{1,8})(.*)/m => method(:id_parse_variant1),
      /(.*)([0-9a-f]{8})(.*)/m => method(:id_parse_variant2),
      /(.*)0x([0-9a-f]{1,8})(.*)/m => method(:id_parse_variant3),
    }
    string_matches_anything = false
    regexps.each do |regexp, callback|
      if string =~ regexp && !string_matches_anything
        string_matches_anything = true
        array += callback.call(string: Regexp.last_match(2), threshold: threshold)
        [Regexp.last_match(1), Regexp.last_match(3)].each do |side_match|
          unless side_match.empty?
            array += id(string: side_match, array: array, threshold: threshold)
          end
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
    array = []
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

  def network(id)
    normal_ids = id(id)
    if normal_ids
      normal_id = normal_ids.first
      return id[2..5].to_i(16).to_s(10)
    end

    false
  end

  MAX_NAME_SIZE = 50

  def name(name, vid)
    return name unless name.size == MAX_NAME_SIZE
    network = network(vid)
    search_range = (MAX_NAME_SIZE - network.size..-1)
    inverted_search_range = (0..MAX_NAME_SIZE - network.size - 1)
    return name[inverted_search_range].strip if name[search_range] == network

    name
  end

  module_function :id, :network, :name
end

require "yaml"
require "json"
require "./version"

# An instance of `Config` provides a `Hash(String, String | Int | Bool)` that is accessed
# via method calls. The method names are the keys of the hash.
#
# For example:
#
# ```
# config = Config.new
#
# config.verbose = true
# pp config.verbose # => true
# if config.quiet?  # => false
#   puts "be quiet"
# else
#   puts "don't be quiet" # => "don't be quiet"
# end
# ```
#
# The `#data` method will return the raw data hash.
#
# ```
# pp config.data # => {"verbose" => true}
# ```
#
# The `Config` class can be initialized from an `IO`, or a `Path`/`String` that points to a
# file. The file can be in either JSON or YAML format. The default format is JSON, but if
# the file cannot be read as JSON, but can be read as YAML, then the format will change to YAML.
#
# ```
# config = Config.from("config.json") # {"verbose" : "true"}
# pp config.verbose                   # => "true"
#
# config = Config.from("config.yaml") # {verbose : true}
# pp config.verbose                   # => true
#
# config = Config.from("config.txt") # {also_verbose : true}
# pp config.also_verbose             # => true
# ```

class Config
  # The Config hash will accept values of String, Int32, or Bool.
  alias ConfigTypes = String | Int32 | Bool

  # The configuration is stored within a constant.
  DATA = Hash(String, ConfigTypes).new

  # The default serialization format is *JSON*. If the config file reads from a file
  # which cannot be read as JSON, but can be read as YAML, then the default format will
  # change to `yaml`.
  getter serialization_format : String = "json"

  # Return the raw config data hash.
  #
  # ```
  # config.data            # => {"verbose" => true}
  # pp tyoeof(config.data) # => Hash(String, Bool | Int32 | String)
  # ```
  #
  def data
    DATA
  end

  # Create a new `Config` instance from a hash. Keys will be turned into `String`, and
  # values, if they are a type other than `Bool`, `Int32`, or `String`, will be turned
  # into `String` as well.
  def self.from(source : Hash(_, _))
    new(source)
  end

  # 
  def self.from(source : IO, format : String = "json")
    case format
    when "json"
      from(JSON.parse(source).as_h).tap(&.serialization_format=("json"))
    else
      from(YAML.parse(source).as_h).tap(&.serialization_format=("yaml")
    end
  rescue ex
    from(YAML.parse(source.rewind).as_h).tap(&.serialization_format=("yaml"))
  end

  def self.from(source : Path)
    format = source =~ /\.ya?ml$/ ? "yaml" : "json"
    File.open(source) { |fh| from(fh, format) }
  end

  def self.from(source : String)
    from(Path.new(source))
  end

  def self.new(source : Hash(_, _))
    obj = Config.new
    source.each do |key, value|
      obj.data[key.to_s] = value.as_bool? || value.as_i? || value.to_s
    end

    obj
  end

  def serialization_format=(format)
    @serialization_format = case format.to_s
                            when "json" then "json"
                            when "yaml" then "yaml"
                            else
                              raise "Unknown serialization format: #{format}; must be 'json' or 'yaml'"
                            end
  end

  def into(target : Hash(_, _))
    target.merge!(data)
  end

  def into(target : IO)
    case serialization_format
    when "json"
      target.write(data.to_json)
    when "yaml"
      target.write(data.to_yaml)
    else
      raise "Unknown serialization format: #{serialization_format}"
    end
  end

  def into(target : Path)
    File.open(target, "w+") { |fh| into(fh) }
  end

  def into(target : String)
    into(Path.new(target))
  end

  # This macro writes the code to write to or access the configuration hash.
  macro method_missing(call)
      {% if call.name == "[]" %}
        DATA[{{ call.args[0].id }}]
      {% elsif call.name == "[]?" %}
        DATA[{{ call.args[0].id }}]?
      {% elsif call.name == "[]=" %}
        DATA[{{ call.args[0].id }}] = {{ call.args[1].id }}
      {% elsif call.name =~ /=/ %}
        DATA[{{ call.name[0..-2].stringify }}] = {{ call.args[0] }}
      {% elsif call.name =~ /\?$/ %}
        DATA[{{ call.name[0..-2].stringify }}]?
      {% else %}
        DATA[{{ call.name.stringify }}]
      {% end %}
    end
end

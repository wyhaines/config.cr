require "yaml"
require "json"
require "./format"
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

  # The default serialization format is `JSON`. If the config file reads from a file
  # which cannot be read as JSON, but can be read as YAML, then the default format will
  # change to `YAML`. This property can also be set manually if one wants to specify the
  # format to use to serialize the config data.
  property serialization_format : Format = Format::JSON

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

  # Create a new `Config` instance from an `IO` object. The format of the data is assumed
  # to be JSON unless otherwise specified. However, if the file can not be parsed as JSON
  # data, the IO will be rewound, and the data will be parsed as YAML.
  def self.from(source : IO, format : Format = Format::JSON)
    case format
    when Format::JSON
      from(::JSON.parse(source).as_h).tap(&.serialization_format=(Format::JSON))
    else
      from(::YAML.parse(source).as_h).tap(&.serialization_format=(Format::YAML))
    end
  rescue ex
    from(::YAML.parse(source.rewind).as_h).tap(&.serialization_format=(Format::YAML))
  end

  # Create a new `Config` instance from a `Path` specifing the file to read.
  def self.from(source : Path)
    format = source =~ /\.ya?ml$/ ? Format::YAML : Format::JSON
    File.open(source) { |fh| from(fh, format) }
  end

  # Create a new `Config` instance from a `String` specifing the path of the file to read.
  def self.from(source : String)
    from(Path.new(source))
  end

  # Instantiate a new `Config` instance from a `Hash`. Keys will be turned into `String`,
  # and values other than `Bool` and `Int32` will be turned into `String`, as well.
  def self.new(source : Hash(_, _))
    obj = Config.new
    source.each do |key, value|
      obj.data[key.to_s] = value.as_bool? || value.as_i? || value.to_s
    end

    obj
  end

  # Insert the data from the this `Config`s hash into the `target` hash.
  def into(target : Hash(_, _))
    target.merge!(data)
  end

  # Serialize the data from this `Config` instance into the `target` IO object.
  def into(target : IO)
    case serialization_format
    when JSON
      target.write(data.to_json)
    when YAML
      target.write(data.to_yaml)
    end
  end

  # Serialize the data from this `Config` instance into the `target` file specified by the `Path`.
  def into(target : Path)
    File.open(target, "w+") { |fh| into(fh) }
  end

  # Serialize the data from this `Config` instance into the `target` file specified by the `String`.
  def into(target : String)
    into(Path.new(target))
  end

  # This macro writes the code for writing to or accessing the configuration hash.
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

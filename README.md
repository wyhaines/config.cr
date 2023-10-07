![Topos Playground CI](https://img.shields.io/github/actions/workflow/status/wyhaines/config.cr/ci.yml?branch=main&style=for-the-badge&logo=GitHub)
[![GitHub release](https://img.shields.io/github/release/wyhaines/config.cr.svg?style=for-the-badge)](https://github.com/wyhaines/config.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/config.cr/latest?style=for-the-badge)

# config

An instance of `Config` provides a `Hash(String, String | Int | Bool)` that can be accessed
via method calls. The method names are the keys of the hash.


```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     config:
       github: your-github-user/config
   ```

2. Run `shards install`

## Usage

```crystal
require "config"
```


```crystal
config = Config.new

config.verbose = true
pp config.verbose # => true
if config.quiet?  # => false
  puts "be quiet"
else
  puts "don't be quiet" # => "don't be quiet"
end
```

The `#data` method will return the raw data hash.

```crystal
pp config.data # => {"verbose" => true}
```

The `Config` class can be initialized from an `IO`, or a `Path`/`String` that points to a
file. The file can be in either JSON or YAML format. The default format is JSON, but if
the file cannot be read as JSON, but can be read as YAML, then the format will change to YAML.

```crystal
config = Config.from("config.json") # {"verbose" : "true"}
pp config.verbose                   # => "true"

config = Config.from("config.yaml") # {verbose : true}
pp config.verbose                   # => true

config = Config.from("config.txt") # {also_verbose : true}
pp config.also_verbose             # => true

## Contributing

1. Fork it (<https://github.com/wyhaines/config/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer

class Config
  # The current version of the shard. This is read from the VERSION file by a precompilation macro.
  VERSION = {{ read_file("#{__DIR__}/../VERSION").chomp }}
end

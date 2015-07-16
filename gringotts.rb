require 'yaml'
require 'oauth'
require 'pp'
require './fetcher'

config = YAML.load_file('config.yml')

fetcher = Fetcher.new

unless ARGV.empty?
  method = ARGV[0].to_s
  config = config[method]
  fetcher.send(method, config)
else
  puts "No module specified"
end
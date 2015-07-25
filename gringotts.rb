require 'yaml'
require 'oauth'
require 'pp'
require './fetcher'

config = YAML.load_file('config.yml')

fetcher = Fetcher.new(config)

unless ARGV.empty?
  method = ARGV[0].to_s
  config = config[method]
  if ARGV[1] === 'mock'
    fetcher.send(method, true)
  else
    fetcher.send(method)
  end
else
  puts "No module specified"
end
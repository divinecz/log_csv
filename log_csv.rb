#!/usr/bin/env ruby
require "rubygems"
gem "log_parser", "= 0.2.2"
# $:.unshift File.dirname($0) + "/../log_parser/lib"
require "log_parser"
require "optparse"
require "csv"

SD_LOGS_PATH = File.dirname(File.expand_path(__FILE__)) + "/sd_logs.yml"
CSV_PATH = File.dirname(File.expand_path(__FILE__)) + "/csv.yml"

options = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} PATH [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on_tail("--version", "Show version") do
    puts OptionParser::Version.join('.')
    exit
  end
end

begin
  options.parse!
rescue OptionParser::ParseError => e
  puts e
end

if ARGV.length == 0 
  options.parse(["-h"]) 
  exit 1 
end

path = ARGV.first
unless File.exists?(path)
  puts "ERROR: Path does not exists"
  exit 1
end
path = File.join(path, "*.log")

def hex_log_to_binary_log(hex_log)
  [hex_log].pack("H*")
end

def load_csv_definitions
  YAML::load(File.read(CSV_PATH))
end

def process_log(file_path)
  puts "Processing '#{file_path}'..."
  File.open(file_path) do |file|
    CSV.open(File.join(File.dirname(file_path), File.basename(file_path) + ".csv"), "w", (RUBY_VERSION >= "1.9.0" ? { :col_sep => ";" } : ";")) do |writer|
      writer << @csv_definitions["columns"]
      while !file.eof? do
        line = file.readline
        hex_log = line.match(/[0-9a-f]{6}:([0-9a-f]{1024})/i)
        hex_log = hex_log.captures[0] if hex_log
        if hex_log
          binary_log = hex_log_to_binary_log(hex_log)
          log = @sdlog_parser.parse(binary_log)
          writer << @csv_definitions["columns"].collect { |column| column == "log_name" ? log[:name] : log[:attributes][column.to_sym] }
        end
      end
    end
  end
end

begin
  @sdlog_parser = LogParser::SDLogParser.new(SD_LOGS_PATH)
  @csv_definitions = load_csv_definitions
  Dir[path].each do |file_path|
    process_log file_path
  end
rescue LogParser::LogParserError => e
  puts "ERROR: " + e
  exit 1
end
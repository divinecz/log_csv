#!/usr/bin/env ruby
require "rubygems"
gem "log_parser", "= 0.2.0"
# $:.unshift File.dirname($0) + "/../log_parser/lib"
require "log_parser"
require "optparse"
require "csv"

SD_LOGS_PATH = File.dirname(File.expand_path(__FILE__)) + "/sd_logs.yml"
CSV_PATH = File.dirname(File.expand_path(__FILE__)) + "/csv.yml"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} PATH [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on_tail("--version", "Show version") do
    puts OptionParser::Version.join('.')
    exit
  end
end.parse!

path = ARGV.first
raise if path.nil?

def hex_log_to_binary_log(hex_log)
  hex_log.to_a.pack("H*")
end

def load_csv_definitions
  YAML::load(File.read(CSV_PATH))
end

def process_log(file_path)
  puts "Processing '#{file_path}'..."
  File.open(file_path) do |file|
    CSV.open(File.join(File.dirname(file_path), File.basename(file_path) + ".csv"), "w", ";") do |writer|
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

@sdlog_parser = LogParser::SDLogParser.new(SD_LOGS_PATH)
@csv_definitions = load_csv_definitions
Dir[File.join(path, "*.log")].each do |file_path|
  process_log file_path
end
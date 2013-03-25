require 'rubygems'
require 'bundler'
Bundler.require(:default)

class WrongFileType < StandardError; end

class RED < Thor
  desc "to_opr FILE", "convert .opr.toml FILE into an .opr usable by ESP-r"
  def to_opr(file)
    raise WrongFileType unless file.chomp.match /.opr.toml$/
    content = File.read file
    opr = TOML::Parser.new(content).parsed
    ap opr
  end
end

RED.start(ARGV)
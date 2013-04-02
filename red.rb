require 'rubygems'
require 'bundler'
Bundler.require(:default)

class WrongFileType < StandardError; end
class InvalidArgument < StandardError; end

class Period
  attr_accessor :start, :stop, :infiltration_rate, :ventilation_rate, :source_zone, :data
  def initialize(params={})
    @start = params[:start]
    @stop = params[:stop]
    @infiltration_rate = params[:infiltration_rate] || 0.08
    @ventilation_rate = params[:ventilation_rate] || 0.000
    @source_zone = params[:source_zone] || 0
    @data = params[:data] || 0.000
  end
end

class RED < Thor
  desc "to_opr FILE", "convert .opr.toml FILE into an .opr usable by ESP-r"
  def to_opr(file)
    raise WrongFileType unless file.chomp.match /.opr.toml$/
    @opr_hash = TOML.load_file file
    ap @opr_hash
    puts '----------------------------------------------'
    ap opr_hash_to_espr_opr(@opr_hash)
  end
  
  private 
  # TODO: export all these into a module
  def opr_hash_to_espr_opr(opr_hash)
    opr = ""
    opr += "*Operations 2.0\n"
    opr += "*date Mon Mar 25 05:41:37 2013  # latest file modification\n"# TODO: Use Date#today or something
    opr += " -11 #{setpoint :low} #{setpoint :mid} #{setpoint :high}\n"
    
    infiltration_rates = [:low, :mid, :high]
    infiltration_rates.each do |infiltration_rate|
      opr += "\t\t #{infiltration_rate infiltration_rate} 0.000 0 0.000\n" # infil, vent, source, data
    end
    
    day_types = [:weekdays, :saturday, :sunday]
    day_types.each do |day_type|
      opr += "\t\t #{no_of_flow_periods_in_day_type day_type}\n"

      # TODO: fix encapsulation the code below is ugly
      periods_in(opr_hash['air_flows']['infiltration'][day_type]).each do |period|
        opr += "\t #{period.start}\n" # start, stop, infil, ventil, source, data
      end
    end
    
    return opr
  end
  
  def setpoint(setpoint)
    case setpoint
    when :low, :mid
      return @opr_hash['air_flows']['controls'][setpoint.to_s+'_setpoint'] || 0
    when :high
      return @opr_hash['air_flows']['controls']['high_setpoint'] || 100
    else
      raise InvalidArgument
    end
  end
  
  def infiltration_rate(rate='')
    if rate == ''
      @opr_hash['air_flows']['infiltration']['rate']
    elsif ((rate == '') || (rate == :low) || (rate == :mid) || (rate ==:high))
      @opr_hash['air_flows']['infiltration'][rate.to_s + '_rate']
    else
      raise InvalidArgument
    end
  end
  
  def no_of_flow_periods_in_day_type(day_type)
    case day_type
    when :weekdays
      @opr_hash['air_flows']['infiltration']['every_day'].length
    when :saturday
      @opr_hash['air_flows']['infiltration']['every_day'].length
    when :sunday
      @opr_hash['air_flows']['infiltration']['every_day'].length
    else
      raise InvalidArgument
    end
    # TODO: add no. of ventilation periods to infiltration periods
    # TODO: add support for [air_flows][infiltration][saturday]
    # TODO: add support for [air_flows][infiltration][sunday]
  end
  
  def periods_in(periods)
    periods_obj = []
    
    periods.each do |period_name, period_params|
    Period.new {
       start: period_params[:start]
       end: ''
     }
    end 
    # TODO: return an instance of Period
  end
end

RED.start(ARGV)
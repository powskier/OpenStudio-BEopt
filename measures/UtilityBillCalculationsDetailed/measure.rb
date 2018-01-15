# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
require 'matrix'
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class UtilityBillCalculationsDetailed < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Calculate Detailed Utility Bills"
  end

  # human readable description
  def description
    return "Calculate utility bills using a detailed method."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculate electric utility bills based on tariffs from the URDB. Calculate other utility bills based on fixed charges for gas, and marginal rates for gas, oil, and propane. If '#{Constants.Auto}' is selected for marginal rates, the state average is used. User can also specify net metering or feed-in tariff PV compensation types, along with corresponding rates."
  end 
  
  def fuel_types
    fuel_types = [  
      "Electricity",
      "Gas",
      "FuelOil#1",
      "Propane",
      "ElectricityProduced"
    ]
    
    return fuel_types
  end
  
  def end_uses
    end_uses = [
      "Facility"
    ]
    
    return end_uses
  end
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new

    tariffs = OpenStudio::StringVector.new
    tariffs << "Autoselect Tariff(s)"
    tariffs << "Custom Tariff"
    CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).each_with_index do |row, i|
      next if i == 0
      utility = row[0]
      name = row[2]
      tariffs << clean_filename("#{utility} - #{name}")
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("tariff_label", tariffs, true)
    arg.setDisplayName("Electricity: Tariff")
    arg.setDescription("The tariff(s) to base the utility bill calculations on.")
    arg.setDefaultValue("Autoselect Tariff(s)")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("custom_tariff", false)
    arg.setDisplayName("Electricity: Custom Tariff File Location")
    arg.setDescription("Absolute (or relative) path to custom tariff file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("gas_fixed", true)
    arg.setDisplayName("Natural Gas: Fixed Charge")
    arg.setUnits("$/month")
    arg.setDescription("Monthly fixed charge for natural gas.")
    arg.setDefaultValue("8.0")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("gas_rate", true)
    arg.setDisplayName("Natural Gas: Marginal Rate")
    arg.setUnits("$/therm")
    arg.setDescription("Price per therm for natural gas.")
    arg.setDefaultValue(Constants.Auto)
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("oil_rate", true)
    arg.setDisplayName("Oil: Marginal Rate")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for fuel oil.")
    arg.setDefaultValue(Constants.Auto)
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("prop_rate", true)
    arg.setDisplayName("Propane: Marginal Rate")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for propane.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    pv_compensation_types = OpenStudio::StringVector.new
    pv_compensation_types << "Net Metering"
    pv_compensation_types << "Feed-In Tariff"
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_compensation_type", pv_compensation_types, true)
    arg.setDisplayName("PV: Compensation Type")
    arg.setDescription("The type of compensation for PV.")
    arg.setDefaultValue("Net Metering")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("pv_sellback_rate", true)
    arg.setDisplayName("PV: Net Metering Annual Excess Sellback Rate")
    arg.setUnits("$/kWh")
    arg.setDescription("The annual excess/net sellback rate for PV. Only applies if the PV compensation type is 'Net Metering'.")
    arg.setDefaultValue("0.03")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("pv_tariff_rate", true)
    arg.setDisplayName("PV: Feed-In Tariff Rate")
    arg.setUnits("$/kWh")
    arg.setDescription("The annual full/gross tariff rate for PV. Only applies if the PV compensation type is 'Feed-In Tariff'.")
    arg.setDefaultValue("0.12")
    args << arg
    
    return args
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new

    # Request the output for each end use/fuel type combination
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = if end_use == "Facility"
                  "#{fuel_type}:#{end_use}"
                else
                  "#{end_use}:#{fuel_type}"
                end
        result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},Hourly;").get
      end
    end

    return result
  end
  
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeStringOutput("electricity")
    buildstock_outputs = [
                          "natural_gas",
                          "propane",
                          "fuel_oil"
                         ]    
    buildstock_outputs.each do |output|
        result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end  
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end
    
    require 'zip'
    
    # Assign the user inputs to variables
    tariff_label = runner.getStringArgumentValue("tariff_label", user_arguments)
    custom_tariff = runner.getOptionalStringArgumentValue("custom_tariff", user_arguments)
    gas_fixed = runner.getOptionalStringArgumentValue("gas_fixed", user_arguments)
    gas_fixed.is_initialized ? gas_fixed = gas_fixed.get : gas_fixed = 0
    pv_compensation_type = runner.getStringArgumentValue("pv_compensation_type", user_arguments)
    pv_sellback_rate = runner.getStringArgumentValue("pv_sellback_rate", user_arguments)
    pv_tariff_rate = runner.getStringArgumentValue("pv_tariff_rate", user_arguments)
    if pv_compensation_type == "Net Metering"
      pv_rate = pv_sellback_rate
    elsif pv_compensation_type == "Feed-In Tariff"
      pv_rate = pv_tariff_rate
    end
    
    fixed_rates = {
                   Constants.FuelTypeGas=>gas_fixed.to_f
                  }
    
    marginal_rates = {
                      Constants.FuelTypeGas=>runner.getStringArgumentValue("gas_rate", user_arguments),
                      Constants.FuelTypeOil=>runner.getStringArgumentValue("oil_rate", user_arguments),
                      Constants.FuelTypePropane=>runner.getStringArgumentValue("prop_rate", user_arguments)
                     }
    
    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # Get the last sql file      
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)
    
    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end
    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end
    
    tariff = nil
    if tariff_label == "Custom Tariff" and custom_tariff.is_initialized
      custom_tariff = custom_tariff.get
      if File.exists?(File.expand_path(custom_tariff))
        tariff = JSON.parse(File.read(custom_tariff), :symbolize_names=>true)[:items][0]
      end
    elsif tariff_label != "Autoselect Tariff(s)"      
      Zip::File.open("#{File.dirname(__FILE__)}/resources/tariffs.zip") do |zip_file|
        tariff = JSON.parse(zip_file.read(tariff_label), :symbolize_names=>true)[:items][0]
      end
    else # autoselect tariff based on distance to simulation epw location
      weather_file = model.getSite.weatherFile.get
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
      closest_usaf = closest_usaf_to_epw(weather_file.latitude, weather_file.longitude, cols.transpose) # minimize distance to simulation epw
      runner.registerInfo("Nearest usaf to #{File.basename(weather_file.url.get)}: #{closest_usaf}")      
      usafs = cols[1].collect { |i| i.to_s }
      usaf_ixs = usafs.each_index.select{|i| usafs[i] == closest_usaf}
      utilityid_to_nsrdbid = {} # {eiaid: [grid_cell, ...], ...}
      usaf_ixs.each do |ix|
        next if cols[4][ix].nil?
        cols[4][ix].split("|").each do |utilityid|
          next if utilityid == "no data"
          if utilityid_to_nsrdbid.keys.include? utilityid
            utilityid_to_nsrdbid[utilityid] << cols[0][ix]
          else
            utilityid_to_nsrdbid[utilityid] = [cols[0][ix]]
          end
        end
      end

      utilityid_to_filename = {} # {eiaid: {utility - name, ...}, ...}
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
      cols.each do |col|
        next unless col[0].include? "eiaid"
        utilityid_to_nsrdbid.keys.each do |utilityid|
          eiaid_ixs = col.each_index.select{|i| col[i] == utilityid}
          eiaid_ixs.each do |ix|
            utility = cols[0][ix].gsub("/", "_").gsub(",", " ").gsub(":", " ").gsub('"', "").gsub(">", "").gsub("<", "").gsub("*", "").strip
            name = cols[2][ix].gsub("/", "_").gsub(",", " ").gsub(":", " ").gsub('"', "").gsub(">", "").gsub("<", "").gsub("*", "").strip
            filename = "#{utility} - #{name}"
            if utilityid_to_filename.keys.include? utilityid
              utilityid_to_filename[utilityid] << filename
            else
              utilityid_to_filename[utilityid] = [filename]
            end
          end
        end
      end
      
      tariffs = []
      utilityid_to_filename.each do |utilityid, filenames|
        filenames.each do |filename|    
          Zip::File.open("#{File.dirname(__FILE__)}/resources/tariffs.zip") do |zip_file|
            tariffs << JSON.parse(zip_file.read("#{filename}.json"), :symbolize_names=>true)[:items][0]
          end
        end          
      end
      
      tariff = tariffs[0] # FIXME: there can be multiple tariffs: multiple labels in multiple eiaids per usaf. average these? register all of them?
    end

    timeseries = {}
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
      
        var_name = "#{fuel_type}:#{end_use}"
        timeseries[var_name] = []
        
        # Get the y axis values
        y_timeseries = sql.timeSeries(ann_env_pd, "Hourly", var_name, "")
        if y_timeseries.empty?
          runner.registerWarning("No data found for Hourly #{var_name}.")
          next
        else
          y_timeseries = y_timeseries.get
          values = y_timeseries.values
        end

        old_units = y_timeseries.units
        new_units, unit_conv = UnitConversions.get_scalar_unit_conversion(var_name, old_units, HelperMethods.reverse_openstudio_fuel_map(fuel_type))
        y_timeseries.dateTimes.each_with_index do |date_time, i|
          y_val = values[i].to_f
          unless unit_conv.nil?
            y_val *= unit_conv
          end
          timeseries[var_name] << y_val.round(5)
        end
        
      end
    end

    weather_file_state = model.getSite.weatherFile.get.stateProvinceRegion
    calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_rate, tariff)
    
    return true
    
  end

  def calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_rate, tariff)
  
    if timeseries["ElectricityProduced:Facility"].empty?
      timeseries["ElectricityProduced:Facility"] = Array.new(timeseries["Electricity:Facility"].length, 0)
    end

    timeseries["ElectricityProduced:Facility"].each_with_index do |val, i|
      timeseries["Electricity:Facility"][i] += timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
    end
  
    fuels = {Constants.FuelTypeElectric=>"Electricity", Constants.FuelTypeGas=>"Natural gas", Constants.FuelTypeOil=>"Oil", Constants.FuelTypePropane=>"Propane"}
    fuels.each do |fuel, file|
      if fuel == Constants.FuelTypeElectric
        report_output(runner, fuel, timeseries["Electricity:Facility"], nil, pv_compensation_type, pv_rate.to_f, nil, timeseries["ElectricityProduced:Facility"], tariff)
      else    
        cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{file}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
        cols[0].each_with_index do |rate_state, i|
          unless HelperMethods.state_code_map(weather_file_state).nil?
            weather_file_state = HelperMethods.state_code_map(weather_file_state)
          end
          next unless rate_state == weather_file_state
          marginal_rate = marginal_rates[fuel]
          if marginal_rate == Constants.Auto
            average_rate = cols[1][i].to_f
            if [Constants.FuelTypeGas].include? fuel
              household_consumption = cols[2][i].to_f
              marginal_rate = average_rate - 12.0 * fixed_rates[fuel] / household_consumption
            else
              marginal_rate = average_rate
            end
          end
          if fuel == Constants.FuelTypeGas and not timeseries["Gas:Facility"].empty?
            report_output(runner, fuel, timeseries["Gas:Facility"], marginal_rate.to_f, pv_compensation_type, pv_rate.to_f, fixed_rates[fuel])
          elsif fuel == Constants.FuelTypeOil and not timeseries["FuelOil#1:Facility"].empty?
            report_output(runner, fuel, timeseries["FuelOil#1:Facility"], marginal_rate.to_f, pv_compensation_type, pv_rate.to_f)
          elsif fuel == Constants.FuelTypePropane and not timeseries["Propane:Facility"].empty?
            report_output(runner, fuel, timeseries["Propane:Facility"], marginal_rate.to_f, pv_compensation_type, pv_rate.to_f)
          end
          break
        end
      end
    end  
  
  end
  
  def report_output(runner, fuel, consumed, rate, pv_compensation_type, pv_rate, fixed=0, produced=nil, tariff=nil)
    total_val = consumed.inject(0){ |sum, x| sum + x }
    if not fuel == Constants.FuelTypeElectric
      total_val = 12.0 * fixed + total_val * rate
    else
      if consumed.length == 8784 # leap year
        consumed = consumed[0..1415] + consumed[1440..-1] # remove leap day
        produced = produced[0..1415] + produced[1440..-1] # remove leap day
      end
      total_val = calculate_electricity_bills(consumed, produced, pv_compensation_type, pv_rate, tariff)
    end
    runner.registerValue(fuel, total_val)
    runner.registerInfo("Registering #{fuel} utility bills.")
  end
  
  def calculate_electricity_bills(load, gen, pv_compensation_type, pv_rate, tariff)

    if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
      unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
      unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
    end

    require "#{File.dirname(__FILE__)}/resources/ssc_api"
  
    # utilityrate3
    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, "analysis_period", 1) # years
    SscApi.set_array(p_data, "degradation", [0]) # annual energy degradation
    SscApi.set_array(p_data, "gen", gen) # system power generated, kW
    SscApi.set_array(p_data, "load", load) # electricity load, kW
    SscApi.set_number(p_data, "system_use_lifetime_output", 0) # 0=hourly first year, 1=hourly lifetime
    SscApi.set_number(p_data, "inflation_rate", 0) # TODO: assume what?
    SscApi.set_number(p_data, "ur_enable_net_metering", 1)
    SscApi.set_number(p_data, "ur_flat_buy_rate", 0)
    if pv_compensation_type == "Net Metering"
      SscApi.set_number(p_data, "ur_nm_yearend_sell_rate", pv_rate)
    elsif pv_compensation_type == "Feed-In Tariff"
      SscApi.set_number(p_data, "ur_flat_sell_rate", pv_rate)
    end    
    unless tariff[:fixedmonthlycharge].nil?
      SscApi.set_number(p_data, "ur_monthly_fixed_charge", tariff[:fixedmonthlycharge]) # $
    end
    
    SscApi.set_number(p_data, "ur_ec_enable", 1)
    SscApi.set_matrix(p_data, "ur_ec_sched_weekday", Matrix.rows(tariff[:energyweekdayschedule]))
    SscApi.set_matrix(p_data, "ur_ec_sched_weekend", Matrix.rows(tariff[:energyweekendschedule]))
    tariff[:energyratestructure].each_with_index do |period, i|
      period.each_with_index do |tier, j|
        unless tier[:adj].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate] + tier[:adj])
        else
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate])
        end
        unless tier[:sell].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_sr", tier[:sell])
        end
        unless tier[:max].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", tier[:max])
        else
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", 1000000000.0)
        end        
      end
    end

    unless tariff[:demandratestructure].nil?
      SscApi.set_matrix(p_data, "ur_dc_sched_weekday", Matrix.rows(tariff[:demandweekdayschedule]))
      SscApi.set_matrix(p_data, "ur_dc_sched_weekend", Matrix.rows(tariff[:demandweekendschedule]))
      SscApi.set_number(p_data, "ur_dc_enable", 1)
      tariff[:demandratestructure].each_with_index do |period, i|
        period.each_with_index do |tier, j|
          unless tier[:adj].nil?
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate] + tier[:adj])
          else
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate])
          end
          unless tier[:max].nil?
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", tier[:max])
          else
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", 1000000000.0)
          end
        end
      end
    end
    
    p_mod = SscApi.create_module("utilityrate3")
    SscApi.execute_module(p_mod, p_data)

    utility_bills = SscApi.get_array(p_data, "year1_monthly_utility_bill_w_sys")
    
    return utility_bills.inject(0){ |sum, x| sum + x }
  
  end
  
  def closest_usaf_to_epw(bldg_lat, bldg_lon, usafs)
    distances = [1000000]
    usafs.each do |usaf|
      if (bldg_lat.to_f - usaf[3].to_f).abs > 1 and (bldg_lon.to_f - usaf[2].to_f).abs > 1 # reduce the set to save some time
        distances << 100000
        next
      end
      km = haversine(bldg_lat.to_f, bldg_lon.to_f, usaf[3].to_f, usaf[2].to_f)
      distances << km
    end    
    return usafs[distances.index(distances.min)][1]    
  end

  def haversine(lat1, lon1, lat2, lon2)
    # convert decimal degrees to radians
    [lon1, lat1, lon2, lat2].each do |l|
      l = UnitConversions.convert(l,"deg","rad")
    end
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = Math.sin(dlat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon/2)**2
    c = 2 * Math.asin(Math.sqrt(a)) 
    km = 6367 * c
    return km
  end
  
  def clean_filename(name)
    name = name.gsub("/", "_")
    name = name.gsub(",", "")
    name = name.gsub(":", " ")
    name = name.gsub('"', "")
    name = name.gsub(">", "")
    name = name.gsub("<", "")
    name = name.gsub("*", "")
    return name.strip
  end

end

# register the measure to be used by the application
UtilityBillCalculationsDetailed.new.registerWithApplication
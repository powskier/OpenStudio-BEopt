# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
require 'matrix'
require 'zip'
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class UtilityBillCalculationsDetailed < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Calculate Detailed Utility Bills"
  end

  # human readable description
  def description
    return "Calls the SAM SDK for calculating utility bills."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calls the utilityrate3 module in the SAM SDK."
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
    Zip::File.open("#{File.dirname(__FILE__)}/resources/tariffs.zip") do |zip_file|
      zip_file.each do |entry|
        next unless entry.file?
        tariffs << entry.name
      end
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("tariff_label", tariffs, true)
    arg.setDisplayName("Electricity: Tariff")
    arg.setDescription("The tariff(s) to use.")
    arg.setDefaultValue("Autoselect Tariff(s)")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("custom_tariff", false)
    arg.setDisplayName("Electricity: Custom Tariff File Location")
    arg.setDescription("Absolute (or relative) path to custom tariff file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("ng_fixed", true)
    arg.setDisplayName("Natural Gas: Fixed Charge")
    arg.setUnits("$/month")
    arg.setDescription("Monthly fixed charge for natural gas.")
    arg.setDefaultValue("8.0")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("ng_rate", true)
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
    
    # Assign the user inputs to variables
    tariff_label = runner.getStringArgumentValue("tariff_label", user_arguments)
    custom_tariff = runner.getOptionalStringArgumentValue("custom_tariff", user_arguments)
    elec_fixed = runner.getOptionalStringArgumentValue("elec_fixed", user_arguments)
    elec_fixed.is_initialized ? elec_fixed = elec_fixed.get : elec_fixed = 0
    ng_fixed = runner.getOptionalStringArgumentValue("ng_fixed", user_arguments)
    ng_fixed.is_initialized ? ng_fixed = ng_fixed.get : ng_fixed = 0
    pv_compensation_type = runner.getStringArgumentValue("pv_compensation_type", user_arguments)
    pv_sellback_rate = runner.getStringArgumentValue("pv_sellback_rate", user_arguments)
    pv_tariff_rate = runner.getStringArgumentValue("pv_tariff_rate", user_arguments)
    if pv_compensation_type == "Net Metering"
      pv_rate = pv_sellback_rate
    elsif pv_compensation_type == "Feed-In Tariff"
      pv_rate = pv_tariff_rate
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
    else
      weather_file = model.getSite.weatherFile.get
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
      closest_usaf = closest_usaf_to_epw(weather_file.latitude, weather_file.longitude, cols.transpose) # minimize distance to simulation epw
      runner.registerInfo("Nearest usaf to #{File.basename(weather_file.url.get)}: #{closest_usaf}")
      # tariff = TODO
    end
    
    marginal_rates = {
                      Constants.FuelTypeElectric=>nil, 
                      Constants.FuelTypeGas=>runner.getStringArgumentValue("ng_rate", user_arguments),
                      Constants.FuelTypeOil=>runner.getStringArgumentValue("oil_rate", user_arguments),
                      Constants.FuelTypePropane=>runner.getStringArgumentValue("prop_rate", user_arguments)
                     }
    
    # get the last model and sql file
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
        new_units, unit_conv = UnitConversions.get_scalar_unit_conversion(var_name, old_units)
        y_timeseries.dateTimes.each_with_index do |date_time, i|
          y_val = values[i]
          if unit_conv.nil? # these unit conversions are not scalars
            if old_units == "C" and new_units == "F"
              y_val = UnitConversions.convert(y_val, "C", "F") # convert C to F
            end
          else # these are scalars
            y_val *= unit_conv
          end
          timeseries[var_name] << y_val.round(3)
        end
        
      end
    end

    if timeseries["ElectricityProduced:Facility"].empty?
      timeseries["ElectricityProduced:Facility"] = Array.new(timeseries["Electricity:Facility"].length, 0)
    end
    
    timeseries["ElectricityProduced:Facility"].each_with_index do |val, i|
      timeseries["Electricity:Facility"][i] -= timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
    end

    weather_file_state = model.getSite.weatherFile.get.stateProvinceRegion
    fuels = {Constants.FuelTypeElectric=>"Electricity", Constants.FuelTypeGas=>"Natural gas", Constants.FuelTypeOil=>"Oil", Constants.FuelTypePropane=>"Propane"}
    fuels.each do |fuel, file|
      if fuel == Constants.FuelTypeElectric
        if not timeseries["Electricity:Facility"].empty?
          report_output(runner, fuel, timeseries["Electricity:Facility"], "kWh", "kWh", nil, pv_compensation_type, pv_rate, timeseries["ElectricityProduced:Facility"], nil, tariff)
        end
      else    
        cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{file}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
        cols[0].each_with_index do |rate_state, i|
          if state_name_to_code.keys.include? weather_file_state
            weather_file_state = state_name_to_code[weather_file_state]
          end
          rate = marginal_rates[fuel]
          if rate == Constants.Auto
            rate = cols[1][i]
          end
          next unless rate_state == weather_file_state
          if fuel == Constants.FuelTypeGas and not timeseries["Gas:Facility"].empty?
            report_output(runner, fuel, timeseries["Gas:Facility"], "kBtu", "therm", rate, pv_compensation_type, pv_rate, nil, ng_fixed)
          elsif fuel == Constants.FuelTypeOil and not timeseries["FuelOil#1:Facility"].empty?
            report_output(runner, fuel, timeseries["FuelOil#1:Facility"], "kBtu", "gal", rate, pv_compensation_type, pv_rate)
          elsif fuel == Constants.FuelTypePropane and not timeseries["Propane:Facility"].empty?
            report_output(runner, fuel, timeseries["Propane:Facility"], "kBtu", "gal", rate, pv_compensation_type, pv_rate)
          end
          break
        end
      end
    end

    return true
 
  end
  
  def state_name_to_code
    return {"Alabama"=>"AL", "Alaska"=>"AK", "Arizona"=>"AZ", "Arkansas"=>"AR","California"=>"CA","Colorado"=>"CO", "Connecticut"=>"CT", "Delaware"=>"DE", "District of Columbia"=>"DC",
            "Florida"=>"FL", "Georgia"=>"GA", "Hawaii"=>"HI", "Idaho"=>"ID", "Illinois"=>"IL","Indiana"=>"IN", "Iowa"=>"IA","Kansas"=>"KS", "Kentucky"=>"KY", "Louisiana"=>"LA",
            "Maine"=>"ME","Maryland"=>"MD", "Massachusetts"=>"MA", "Michigan"=>"MI", "Minnesota"=>"MN","Mississippi"=>"MS", "Missouri"=>"MO", "Montana"=>"MT","Nebraska"=>"NE", "Nevada"=>"NV",
            "New Hampshire"=>"NH", "New Jersey"=>"NJ", "New Mexico"=>"NM", "New York"=>"NY","North Carolina"=>"NC", "North Dakota"=>"ND", "Ohio"=>"OH", "Oklahoma"=>"OK",
            "Oregon"=>"OR", "Pennsylvania"=>"PA", "Puerto Rico"=>"PR", "Rhode Island"=>"RI","South Carolina"=>"SC", "South Dakota"=>"SD", "Tennessee"=>"TN", "Texas"=>"TX",
            "Utah"=>"UT", "Vermont"=>"VT", "Virginia"=>"VA", "Washington"=>"WA", "West Virginia"=>"WV","Wisconsin"=>"WI", "Wyoming"=>"WY"}
  end
  
  def report_output(runner, fuel, vals, from, to, rate, pv_compensation_type, pv_rate, produced=nil, fixed=0, tariff=nil)
    total_val = 0.0
    vals.each do |val|
      total_val += val.to_f
    end
    fixed = fixed.to_f
    rate = rate.to_f
    if not fuel == Constants.FuelTypeElectric
      if to == "gal"
        total_val = UnitConversions.btu2gal(UnitConversions.convert(total_val, "kBtu", "Btu"), fuel)
      else
        total_val = UnitConversions.convert(total_val, from, to)
      end
      runner.registerValue(fuel, 12.0 * fixed + total_val * rate)
    else
      if vals.length == 8784 # leap year
        vals = vals[0..1415] + vals[1440..-1] # remove leap day
        produced = produced[0..1415] + produced[1440..-1] # remove leap day
      end
      total_val = calculate_electricity_bills(vals, produced, tariff, pv_compensation_type, pv_rate.to_f)
      runner.registerValue(fuel, total_val)
    end    
    runner.registerInfo("Registering #{fuel} utility bills.")
  end
  
  def calculate_electricity_bills(vals, produced, tariff, pv_compensation_type, pv_rate)
  
    if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
      unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
      unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
    end

    require "#{File.dirname(__FILE__)}/resources/ssc_api"
  
    # utilityrate3
    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, "analysis_period", 1) # years
    SscApi.set_array(p_data, "degradation", [0]) # annual energy degradation
    SscApi.set_array(p_data, "gen", produced) # system power generated, kW
    SscApi.set_array(p_data, "load", vals) # electricity load, kW
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
  
end

# register the measure to be used by the application
UtilityBillCalculationsDetailed.new.registerWithApplication
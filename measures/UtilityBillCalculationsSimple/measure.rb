# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class UtilityBillCalculationsSimple < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Calculate Simple Utility Bills"
  end

  # human readable description
  def description
    return "Calculate utility bills using a simple method."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculate utility bills based on user-entered fixed charges and marginal rates. If '#{Constants.Auto}' is selected for marginal rates, the state average is used."
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
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("elec_fixed", true)
    arg.setDisplayName("Electricity: Fixed Charge")
    arg.setUnits("$/month")
    arg.setDescription("Monthly fixed charge for electricity.")
    arg.setDefaultValue("8.0")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("elec_rate", true)
    arg.setDisplayName("Electricity: Marginal Rate")
    arg.setUnits("$/kWh")
    arg.setDescription("Price per kilowatt-hour for electricity.")
    arg.setDefaultValue(Constants.Auto)
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
    
    # Assign the user inputs to variables
    elec_fixed = runner.getOptionalStringArgumentValue("elec_fixed", user_arguments)
    elec_fixed.is_initialized ? elec_fixed = elec_fixed.get : elec_fixed = 0
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
                   Constants.FuelTypeElectric=>elec_fixed.to_f,
                   Constants.FuelTypeGas=>gas_fixed.to_f
                  }
    
    marginal_rates = {
                      Constants.FuelTypeElectric=>runner.getStringArgumentValue("elec_rate", user_arguments), 
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
    calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_rate)

    return true
 
  end
  
  def calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_rate)
  
    if timeseries["ElectricityProduced:Facility"].empty?
      timeseries["ElectricityProduced:Facility"] = Array.new(timeseries["Electricity:Facility"].length, 0)
    end

    timeseries["ElectricityProduced:Facility"].each_with_index do |val, i|
      timeseries["Electricity:Facility"][i] += timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
    end
  
    fuels = {Constants.FuelTypeElectric=>"Electricity", Constants.FuelTypeGas=>"Natural gas", Constants.FuelTypeOil=>"Oil", Constants.FuelTypePropane=>"Propane"}
    fuels.each do |fuel, file|
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{file}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
      cols[0].each_with_index do |rate_state, i|
        unless HelperMethods.state_code_map(weather_file_state).nil?
          weather_file_state = HelperMethods.state_code_map(weather_file_state)
        end
        next unless rate_state == weather_file_state
        marginal_rate = marginal_rates[fuel]
        if marginal_rate == Constants.Auto
          average_rate = cols[1][i].to_f
          if [Constants.FuelTypeElectric, Constants.FuelTypeGas].include? fuel
            household_consumption = cols[2][i].to_f
            marginal_rate = average_rate - 12.0 * fixed_rates[fuel] / household_consumption
          else
            marginal_rate = average_rate
          end
        end
        if fuel == Constants.FuelTypeElectric and not timeseries["Electricity:Facility"].empty?
          report_output(runner, fuel, timeseries["Electricity:Facility"], marginal_rate.to_f, pv_compensation_type, pv_rate.to_f, fixed_rates[fuel], timeseries["ElectricityProduced:Facility"])
        elsif fuel == Constants.FuelTypeGas and not timeseries["Gas:Facility"].empty?
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
  
  def report_output(runner, fuel, consumed, rate, pv_compensation_type, pv_rate, fixed=0, produced=nil)
    total_val = consumed.inject(0){ |sum, x| sum + x }
    if not fuel == Constants.FuelTypeElectric
      total_val = 12.0 * fixed + total_val * rate
    else
      if consumed.length == 8784 # leap year
        consumed = consumed[0..1415] + consumed[1440..-1] # remove leap day
        produced = produced[0..1415] + produced[1440..-1] # remove leap day
      end
      total_val = calculate_electricity_bills(consumed, produced, fixed, rate, pv_compensation_type, pv_rate)
    end
    runner.registerValue(fuel, total_val)
    runner.registerInfo("Registering #{fuel} utility bills.")
  end
  
  def calculate_electricity_bills(load, gen, fixed, rate, pv_compensation_type, pv_rate)
  
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
    SscApi.set_number(p_data, "ur_monthly_fixed_charge", fixed)
    SscApi.set_number(p_data, "ur_flat_buy_rate", rate)
    if pv_compensation_type == "Net Metering"
      SscApi.set_number(p_data, "ur_nm_yearend_sell_rate", pv_rate)
    elsif pv_compensation_type == "Feed-In Tariff"
      SscApi.set_number(p_data, "ur_flat_sell_rate", pv_rate)
    end
    
    p_mod = SscApi.create_module("utilityrate3")
    SscApi.execute_module(p_mod, p_data)

    utility_bills = SscApi.get_array(p_data, "year1_monthly_utility_bill_w_sys")
    
    return utility_bills.inject(0){ |sum, x| sum + x }
  
  end
  
end

# register the measure to be used by the application
UtilityBillCalculationsSimple.new.registerWithApplication
# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require 'matrix'

#start the measure
class UtilityBillCalculations < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Utility Bill Calculations"
  end

  # human readable description
  def description
    return "Calls SAM SDK."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calls SAM SDK."
  end 
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_dir", true)
    arg.setDisplayName("Run Directory")
    arg.setDescription("Relative path of the run directory.")
    arg.setDefaultValue("..")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("api_key", false)
    arg.setDisplayName("API Key")
    arg.setDescription("Call the API and pull JSON tariff file(s) with EIA ID corresponding to the EPW region.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("tariff_directory", false)
    arg.setDisplayName("Tariff Directory")
    arg.setDescription("Absolute (or relative) directory to tariff files.")
    arg.setDefaultValue("./resources/tariffs")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("tariff_file_name", false)
    arg.setDisplayName("Tariff File Name")
    arg.setDescription("Name of the JSON tariff file. Leave blank if pulling JSON tariff file(s) with EIA ID corresponding to the EPW region.")
    args << arg
    
    return args
  end
  
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeStringOutput("grid_cells")
    result << OpenStudio::Measure::OSOutput.makeStringOutput("total_electricity")
    buildstock_outputs = [
                          "total_natural_gas",
                          "total_propane",
                          "total_oil"
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

    if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
      unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
      unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
    end

    require "#{File.dirname(__FILE__)}/resources/ssc_api"
    
    # Assign the user inputs to variables
    run_dir = runner.getStringArgumentValue("run_dir", user_arguments)
    api_key = runner.getOptionalStringArgumentValue("api_key", user_arguments)
    api_key.is_initialized ? api_key = api_key.get : api_key = nil
    tariff_directory = runner.getOptionalStringArgumentValue("tariff_directory", user_arguments)
    tariff_directory.is_initialized ? tariff_directory = tariff_directory.get : tariff_directory = nil
    tariff_file_name = runner.getOptionalStringArgumentValue("tariff_file_name", user_arguments)
    tariff_file_name.is_initialized ? tariff_file_name = tariff_file_name.get : tariff_file_name = nil    

    unless (Pathname.new tariff_directory).absolute?
      tariff_directory = File.expand_path(File.join(File.dirname(__FILE__), tariff_directory))
    end
    
    unless tariff_file_name.nil?
      tariff_file_name = File.join(tariff_directory, tariff_file_name)
      unless File.exists?(tariff_file_name) and tariff_file_name.downcase.end_with? ".json"
        runner.registerError("'#{tariff_file_name}' does not exist or is not a JSON file.")
        return false
      end
    end

    if !File.exist?(tariff_directory)
      FileUtils.mkdir_p(tariff_directory)
    end
    
    # load profile
    timeseries_file = File.expand_path(File.join(run_dir, "enduse_timeseries.csv"))
    unless File.exists?(timeseries_file)
      runner.registerWarning("'#{timeseries_file}' does not exist.")
      return true
    end    
    cols = CSV.read(timeseries_file).transpose
    elec_load = nil
    elec_generated = nil
    gas_load = nil
    oil_load = nil
    prop_load = nil
    cols.each do |col|
      if col[0].include? "Electricity:Facility"
        elec_load = col[1..-1]
      elsif col[0].include? "PV:Electricity"
        elec_generated = col[1..-1]
      elsif col[0].include? "Gas:Facility"
        gas_load = col[1..-1]
      elsif col[0].include? "FuelOil#1:Facility"
        oil_load = col[1..-1]
      elsif col[0].include? "Propane:Facility"
        prop_load = col[1..-1]
      end
    end
    
    if elec_generated.nil?
      elec_generated = Array.new(elec_load.length, 0)
    end
    
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
    weather_file = runner.lastOpenStudioModel.get.getSite.weatherFile.get
    
    # tariffs
    tariffs = []
    rate_ids = {}

    if not tariff_file_name.nil?
      
      tariff = JSON.parse(File.read(tariff_file_name), :symbolize_names=>true)[:items][0]
      tariffs << tariff
      
      utility_id, getpage = File.basename(tariff_file_name).split("_")
      rate_ids[tariff[:eiaid].to_s] = [tariff[:label].to_s]
      
      ids = cols[4].collect { |i| i.to_s }
      indexes = ids.each_index.select{|i| ids[i] == tariff[:eiaid].to_s}
      utility_ids = {}
      indexes.each do |ix|
        if utility_ids.keys.include? cols[4][ix]
          utility_ids[cols[4][ix]] << cols[0][ix]
        else
          utility_ids[cols[4][ix]] = [cols[0][ix]]
        end
      end
      
    else
    
      closest_usaf = closest_usaf_to_epw(weather_file.latitude, weather_file.longitude, cols.transpose) # minimize distance to resstock epw
      runner.registerInfo("Nearest ResStock usaf to #{File.basename(weather_file.url.get)}: #{closest_usaf}")
      
      usafs = cols[1].collect { |i| i.to_s }
      indexes = usafs.each_index.select{|i| usafs[i] == closest_usaf}
      utility_ids = {}
      indexes.each do |ix|
        next if cols[4][ix].nil?
        cols[4][ix].split("|").each do |utility_id|
          next if utility_id == "no data"
          if utility_ids.keys.include? utility_id
            utility_ids[utility_id] << cols[0][ix]
          else
            utility_ids[utility_id] = [cols[0][ix]]
          end
        end
      end

      cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
      cols.each do |col|
        unless col[0].nil?
          next unless col[0].include? "eiaid"
          utility_ids.keys.each do |utility_id|
            utility_ixs = col.each_index.select{|i| col[i] == utility_id}
            utility_ixs.each do |utility_ix|
              if rate_ids.keys.include? utility_id
                rate_ids[utility_id] << cols[3][utility_ix]
              else
                rate_ids[utility_id] = [cols[3][utility_ix]]
              end
            end
          end
        end
      end
    
    end
    
    uri = URI('http://api.openei.org/utility_rates?')
    if not tariff_directory.nil?
    
      rate_ids.each do |utility_id, getpages|
        getpages.each do |getpage|
      
          runner.registerInfo("Searching cached dir on #{utility_id}_#{getpage}.json.")
          unless (Pathname.new tariff_directory).absolute?
            tariff_directory = File.expand_path(File.join(File.dirname(__FILE__), tariff_directory))
          end
          tariff_file_name = File.join(tariff_directory, "#{utility_id}_#{getpage}.json")
          if File.exists?(tariff_file_name)

            tariff = JSON.parse(File.read(tariff_file_name), :symbolize_names=>true)[:items][0]
            tariffs << tariff

          else
          
            runner.registerInfo("Could not find #{utility_id}_#{getpage}.json in cached dir.")

            if not api_key.nil?
              
              tariff = make_api_request(api_key, uri, tariff_file_name, runner)
              if tariff.nil?
                next
              end
              tariffs << tariff

            else
            
              runner.registerInfo("Did not supply an API Key, skipping #{utility_id}_#{getpage}.")
            
            end
            
          end
          
        end
      end

    end
    
    grid_cells = []
    electricity_bills = []
    tariffs.each do |tariff|
    
      begin
    
        # utilityrate3
        p_data = SscApi.create_data_object
        SscApi.set_number(p_data, 'analysis_period', 1)
        SscApi.set_array(p_data, 'degradation', [0])
        SscApi.set_array(p_data, 'gen', elec_generated) # kW
        SscApi.set_array(p_data, 'load', elec_load) # kW
        SscApi.set_number(p_data, 'system_use_lifetime_output', 0) # TODO: what should this be?
        SscApi.set_number(p_data, 'inflation_rate', 0) # TODO: assume what?
        SscApi.set_number(p_data, 'ur_flat_buy_rate', 0) # TODO: how to get this from list of energyratestructure rates?
        unless tariff[:fixedmonthlycharge].nil?
          SscApi.set_number(p_data, 'ur_monthly_fixed_charge', tariff[:fixedmonthlycharge]) # $
        end
        unless tariff[:demandratestructure].nil?
          SscApi.set_matrix(p_data, 'ur_dc_sched_weekday', Matrix.rows(tariff[:demandweekdayschedule]))
          SscApi.set_matrix(p_data, 'ur_dc_sched_weekend', Matrix.rows(tariff[:demandweekendschedule]))
          SscApi.set_number(p_data, 'ur_dc_enable', 1)
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
        SscApi.set_number(p_data, 'ur_ec_enable', 1)
        SscApi.set_matrix(p_data, 'ur_ec_sched_weekday', Matrix.rows(tariff[:energyweekdayschedule]))
        SscApi.set_matrix(p_data, 'ur_ec_sched_weekend', Matrix.rows(tariff[:energyweekendschedule]))
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
        
        p_mod = SscApi.create_module("utilityrate3")
        SscApi.execute_module(p_mod, p_data)
        
        # demand charges fixed
        demand_charges_fixed = SscApi.get_array(p_data, 'charge_w_sys_dc_fixed')[1]
        
        # demand charges tou
        demand_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_dc_tou')[1]
        
        # energy charges flat
        energy_charges_flat = SscApi.get_array(p_data, 'charge_w_sys_ec_flat')[1]
        
        # energy charges tou
        energy_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_ec')[1]
        
        # annual bill
        utility_bills = SscApi.get_array(p_data, 'year1_monthly_utility_bill_w_sys')
        
        grid_cells << utility_ids[tariff[:eiaid].to_s] * ";"
        electricity_bills << "#{tariff[:label].to_s}=#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)}"
        
      rescue => error
      
        runner.registerWarning("#{error.backtrace}.")
        
      end
      
    end

    unless electricity_bills.empty?
      runner.registerValue("grid_cells", grid_cells.join("|"))
      runner.registerValue("total_electricity", electricity_bills.join("|"))
      runner.registerInfo("Registering electricity bills.")
    end
    
    fuels = ["Natural gas", "Oil", "Propane"]
    fuels.each do |fuel|
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{fuel}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
      cols[0].each_with_index do |rate_state, i|
        weather_file_state = weather_file.stateProvinceRegion
        if state_name_to_code.keys.include? weather_file_state
          weather_file_state = state_name_to_code[weather_file_state]
        end
        next unless rate_state == weather_file_state
        if fuel == "Natural gas" and not gas_load.nil?
          report_output(runner, "total_#{fuel.downcase}", gas_load, "kBtu", "therm", cols[1][i], fuel)
        elsif fuel == "Oil" and not oil_load.nil?
          report_output(runner, "total_#{fuel.downcase}", oil_load, "kBtu", "gal", cols[1][i], fuel)
        elsif fuel == "Propane" and not prop_load.nil?
          report_output(runner, "total_#{fuel.downcase}", prop_load, "kBtu", "gal", cols[1][i], fuel)
        end
        break
      end
    end

    return true
 
  end
  
  def make_api_request(api_key, uri, tariff_file_name, runner)
    utility_id, getpage = File.basename(tariff_file_name).split("_")
    runner.registerInfo("Making api request on getpage=#{getpage}.")
    params = {'version':3, 'format':'json', 'detail':'full', 'getpage':getpage, 'api_key':api_key}
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    response = JSON.parse(response.body, :symbolize_names=>true)
    if response.keys.include? :error
      runner.registerError(response[:error][:message])
      return nil
    else
      File.open(tariff_file_name, "w") do |f|
        f.write(response)
      end
    end
    return response[:items][0]
  end
  
  def state_name_to_code
    return {"Alabama"=>"AL", "Alaska"=>"AK", "Arizona"=>"AZ", "Arkansas"=>"AR","California"=>"CA",
            "Colorado"=>"CO", "Connecticut"=>"CT", "Delaware"=>"DE", "District of Columbia"=>"DC",
            "Florida"=>"FL", "Georgia"=>"GA", "Hawaii"=>"HI", "Idaho"=>"ID", "Illinois"=>"IL",
            "Indiana"=>"IN", "Iowa"=>"IA","Kansas"=>"KS", "Kentucky"=>"KY", "Louisiana"=>"LA",
            "Maine"=>"ME","Maryland"=>"MD", "Massachusetts"=>"MA", "Michigan"=>"MI", "Minnesota"=>"MN",
            "Mississippi"=>"MS", "Missouri"=>"MO", "Montana"=>"MT","Nebraska"=>"NE", "Nevada"=>"NV",
            "New Hampshire"=>"NH", "NewJersey"=>"NJ", "New Mexico"=>"NM", "New York"=>"NY",
            "North Carolina"=>"NC", "North Dakota"=>"ND", "Ohio"=>"OH", "Oklahoma"=>"OK",
            "Oregon"=>"OR", "Pennsylvania"=>"PA", "Puerto Rico"=>"PR", "Rhode Island"=>"RI",
            "South Carolina"=>"SC", "South Dakota"=>"SD", "Tennessee"=>"TN", "Texas"=>"TX",
            "Utah"=>"UT", "Vermont"=>"VT", "Virginia"=>"VA", "Washington"=>"WA", "West Virginia"=>"WV",
            "Wisconsin"=>"WI", "Wyoming"=>"WY"}
  end
  
  def report_output(runner, name, vals, os_units, desired_units, rate, fuel)
    total_val = 0.0
    vals.each do |val|
        total_val += val.to_f
    end
    unless desired_units == "gal"
      runner.registerValue(name, (OpenStudio::convert(total_val, os_units, desired_units).get * rate.to_f).round(2))
    else
      if name.include? "oil"
        runner.registerValue(name, (total_val * 1000.0 / 139000 * rate.to_f).round(2))
      elsif name.include? "propane"
        runner.registerValue(name, (total_val * 1000.0 / 91600 * rate.to_f).round(2))
      end
    end
    runner.registerInfo("Registering #{fuel.downcase} utility bills.")
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
      l = OpenStudio.convert(l,"deg","rad").get
    end
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = Math.sin(dlat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon/2)**2
    c = 2 * Math.asin(Math.sqrt(a)) 
    km = 6367 * c
    return km
  end
  
end

# register the measure to be used by the application
UtilityBillCalculations.new.registerWithApplication
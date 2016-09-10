# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialHotWaterHeaterTanklessElectric < OpenStudio::Ruleset::ModelUserScript

    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Electric Tankless Water Heater"
    end
  
    def description
        return "This measure adds a new residential electric tankless water heater to the model based on user inputs. If there is already an existing residential water heater in the model, it is replaced. For multifamily buildings, the water heater can be set for all units of the building."
    end
  
    def modeler_description
        return "The measure will create a new instance of the OS:WaterHeater:Mixed object representing a electric tankless water heater. The water heater will be placed on the plant loop 'Domestic Hot Water Loop'. If this loop already exists, any water heater on that loop will be removed and replaced with a water heater consistent with this measure. If it doesn't exist, it will be created."
    end

    #define the arguments that the user will input
    def arguments(model)
        ruleset = OpenStudio::Ruleset
    
        osargument = ruleset::OSArgument
    
        args = ruleset::OSArgumentVector.new

        # make an argument for hot water setpoint temperature
        dhw_setpoint = osargument::makeDoubleArgument("dhw_setpoint_temperature", true)
        dhw_setpoint.setDisplayName("Setpoint")
        dhw_setpoint.setDescription("Water heater setpoint temperature.")
        dhw_setpoint.setUnits("F")
        dhw_setpoint.setDefaultValue(125)
        args << dhw_setpoint
	
        # make an argument for water_heater_location
        thermal_zones = model.getThermalZones
        thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
        thermal_zone_names << Constants.Auto
        water_heater_location = osargument::makeChoiceArgument("water_heater_location",thermal_zone_names, true)
        water_heater_location.setDefaultValue(Constants.Auto)
        water_heater_location.setDisplayName("Location")
        water_heater_location.setDescription("Thermal zone where the water heater is located. #{Constants.Auto} will locate the water heater according the BA House Simulation Protocols: A garage (if available) or the living space in hot-dry and hot-humid climates, a basement (finished or unfinished, if available) or living space in all other climates.")
	
        args << water_heater_location

        # make an argument for water_heater_capacity
        water_heater_capacity = osargument::makeStringArgument("water_heater_capacity", true)
        water_heater_capacity.setDisplayName("Input Capacity")
        water_heater_capacity.setDescription("The maximum energy input rating of the water heater.")
        water_heater_capacity.setUnits("kW")
        water_heater_capacity.setDefaultValue("12.0")
        args << water_heater_capacity

        # make an argument for the rated energy factor
        rated_energy_factor = osargument::makeStringArgument("rated_energy_factor", true)
        rated_energy_factor.setDisplayName("Rated Energy Factor")
        rated_energy_factor.setDescription("For water heaters, Energy Factor is the ratio of useful energy output from the water heater to the total amount of energy delivered from the water heater. The higher the EF is, the more efficient the water heater. Procedures to test the EF of water heaters are defined by the Department of Energy in 10 Code of Federal Regulation Part 430, Appendix E to Subpart B.")
        rated_energy_factor.setDefaultValue("0.99")
        args << rated_energy_factor

        # make an argument for cycling_derate
        water_heater_cycling_derate = osargument::makeDoubleArgument("water_heater_cycling_derate", true)
        water_heater_cycling_derate.setDisplayName("Cycling Derate")
        water_heater_cycling_derate.setDescription("Annual energy derate for cycling inefficiencies -- accounts for the impact of thermal cycling and small hot water draws on the heat exchanger. CEC's 2008 Title24 implemented an 8% derate for tankless water heaters. ")
        water_heater_cycling_derate.setUnits("Frac")
        water_heater_cycling_derate.setDefaultValue(0.08)
        args << water_heater_cycling_derate
    
        return args
    end #end the arguments method

    #define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

	
        #Assign user inputs to variables
        cap = runner.getStringArgumentValue("water_heater_capacity",user_arguments)
        ef = runner.getStringArgumentValue("rated_energy_factor",user_arguments)
        cd = runner.getDoubleArgumentValue("water_heater_cycling_derate",user_arguments)
        water_heater_loc = runner.getStringArgumentValue("water_heater_location",user_arguments)
        t_set = runner.getDoubleArgumentValue("dhw_setpoint_temperature",user_arguments).to_f
        
        tanktype = Constants.WaterHeaterTypeTankless
	
        #Validate inputs
        if not runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end
	
        # Validate inputs further
        valid_ef = validate_rated_energy_factor(ef, runner)
        if valid_ef.nil?
            return false
        end
        valid_t_set = validate_setpoint_temperature(t_set, runner)
        if valid_t_set.nil?
            return false
        end
        valid_cap = validate_water_heater_capacity(cap, runner)
        if valid_cap.nil?
            return false
        end
        valid_cd = validate_water_heater_cycling_derate(cd, runner)
        if valid_cd.nil?
            return false
        end
        
        # Get number of units
        num_units = Geometry.get_num_units(model, runner)
        if num_units.nil?
            return false
        end

        #Check if mains temperature has been set
        if !model.getSite.siteWaterMainsTemperature.is_initialized
            runner.registerError("Mains water temperature must be set before adding a water heater.")
            return false
        end
        
        (1..num_units).to_a.each do |unit_num|
        
            # Get unit beds/baths/spaces
            nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
            if unit_spaces.nil?
                runner.registerError("Could not determine the spaces associated with unit #{unit_num}.")
                return false
            end
            if nbeds.nil? or nbaths.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
                return false
            end
    
            #If location is Auto, get the location
            if water_heater_loc == Constants.Auto
                water_heater_tz = Waterheater.get_water_heater_location_auto(model, unit_spaces, runner)
                if water_heater_tz.nil?
                    runner.registerError("The water heater cannot be automatically assigned to a thermal zone. Please manually select which zone the water heater should be located in.")
                    return false
                end
            else
                unit_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)
                water_heater_tz = Geometry.get_thermal_zone_from_string(unit_zones, water_heater_loc.to_s)
                next if water_heater_tz.nil?
            end

            #Check if a DHW plant loop already exists, if not add it
            loop = nil
        
            model.getPlantLoops.each do |pl|
                if pl.name.to_s == Constants.PlantLoopDomesticWater(unit_num)
                    loop = pl
                    #Remove any existing water heater
                    wh_removed = false
                    pl.supplyComponents.each do |wh|
                        next if !wh.to_WaterHeaterMixed.is_initialized and !wh.to_WaterHeaterStratified.is_initialized and !wh.to_WaterHeaterHeatPump.is_initialized
                        wh.remove
                        wh_removed = true
                    end
                    if wh_removed
                        runner.registerInfo("Removed existing water heater from plant loop #{pl.name.to_s}.")
                    end
                end
            end
            
            if loop.nil?
                runner.registerInfo("A new plant loop for DHW will be added to the model")
                runner.registerInitialCondition("No water heater model currently exists")
                loop = Waterheater.create_new_loop(model, Constants.PlantLoopDomesticWater(unit_num))
            end

            if loop.components(OpenStudio::Model::PumpConstantSpeed::iddObjectType).empty?
                new_pump = Waterheater.create_new_pump(model)
                new_pump.addToNode(loop.supplyInletNode)
            end

            if loop.supplyOutletNode.setpointManagers.empty?
                new_manager = Waterheater.create_new_schedule_manager(t_set, model)
                new_manager.addToNode(loop.supplyOutletNode)
            end

            new_heater = Waterheater.create_new_heater(Constants.ObjectNameWaterHeater(unit_num), cap, Constants.FuelTypeElectric, 1, nbeds, nbaths, ef, 0, t_set, water_heater_tz, 0, 0, tanktype, cd, model, runner)
        
            loop.addSupplyBranchForComponent(new_heater)
            
        end
            
        register_final_conditions(runner, model)
  
        return true
 
    end #end the run method

    private

    def register_final_conditions(runner, model)
        final_condition = list_water_heaters(model, runner).join("\n")
        runner.registerFinalCondition(final_condition)
    end    

    def list_water_heaters(model, runner)
        water_heaters = []

        existing_heaters = model.getWaterHeaterMixeds
        for heater in existing_heaters do
            runner.registerInfo("Heater exists and it's named #{heater.name.get}")
            heatername = heater.name.get
            loopname = heater.plantLoop.get.name.get

            capacity_si = heater.getHeaterMaximumCapacity.get
            capacity = OpenStudio.convert(capacity_si.value, capacity_si.units.standardString, "kW").get
            volume_si = heater.getTankVolume.get
            volume = OpenStudio.convert(volume_si.value, volume_si.units.standardString, "gal").get
            te = heater.getHeaterThermalEfficiency.get.value
          
            water_heaters << "Water heater '#{heatername}' added to plant loop '#{loopname}', with a capacity of #{capacity.round(1)} kW." +
            " and a burner efficiency of  #{te.round(2)}."
        end
        water_heaters
    end

    def validate_rated_energy_factor(ef, runner)
        return true if (ef == Constants.Auto)  # flag for autosizing
        ef = ef.to_f

        if (ef >= 1)
            runner.registerError("Rated energy factor has a maximum value of 1.0 for electric water heaters.")
            return nil
        end
        if (ef <= 0)
            runner.registerError("Rated energy factor must be greater than 0. Make sure that the entered value is a number > 0.0")
            return nil
        end
        if (ef <0.96)
            runner.registerWarning("Rated energy factor for commercially available electric tankless water heaters should be greater than 0.96")
        end    
        return true
    end
  
    def validate_setpoint_temperature(t_set, runner)
        if (t_set <= 0)
            runner.registerError("Hot water temperature must be greater than 0.")
            return nil
        end
        if (t_set >= 212)
            runner.registerError("Hot water temperature must be less than the boiling point of water.")
            return nil
        end
        if (t_set > 140)
            runner.registerWarning("Hot water setpoint schedule DHW_Temp has values greater than 140F. This temperature, if achieved, may cause scalding.")
        end    
        if (t_set < 120)
            runner.registerWarning("Hot water setpoint schedule DHW_Temp has values less than 120F. This temperature may promote the growth of Legionellae or other bacteria.")               
        end    
        return true
    end

    def validate_water_heater_capacity(cap, runner)
        return true if cap == Constants.Auto # Autosized
        cap = cap.to_f

        if cap <= 0
            runner.registerError("Electric tankless water heater nominal capacity must be greater than 0 kBtu/hr. Make sure that the entered capacity is a number greater than 0 or #{Constants.Auto}.")
            return nil
        end
        if cap < 2.4
            runner.registerWarning("Commercially available residential electric tankless water heaters should have a nominal capacity greater than 2.4 kW.")
        end
        return true
    end
    
    def validate_water_heater_cycling_derate(cd, runner)
        if (cd < 0)
            runner.registerError("Gas tankless water heater cycling derate must be at least 0 and at most 1.")
            return nil
        end
        if (cd > 1)
            runner.registerError("Gas tankless water heater cycling derate must be at least 0 and at most 1.")
            return nil
        end
        if (cd > 0.20)
            runner.registerWarning("Most tankless water heaters have a cycling derate of about 0.08, double check inputs.")
        end
        return true
    end
  
  
end #end the measure

#this allows the measure to be use by the application
ResidentialHotWaterHeaterTanklessElectric.new.registerWithApplication

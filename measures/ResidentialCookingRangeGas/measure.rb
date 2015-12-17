require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ResidentialCookingRange < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Gas Cooking Range"
  end
  
  def description
    return "Adds (or replaces) a residential cooking range with the specified efficiency, operation, and schedule."
  end
  
  def modeler_description
    return "Since there is no Cooking Range object in OpenStudio/EnergyPlus, we look for a GasEquipment object with the name that denotes it is a residential cooking range. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for rangess (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for number of bedrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "2" 
	chs << "3"
	chs << "4"
	chs << "5+"
	num_br = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Br", chs, true)
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue("3")
	args << num_br

	#make a double argument for cooktop EF
	c_ef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("C_ef")
	c_ef.setDisplayName("Cooktop Energy Factor")
	c_ef.setDescription("Cooktop energy factor determined by DOE test procedures for cooking appliances (DOE 1997).")
	c_ef.setDefaultValue(0.74)
	args << c_ef

	#make a double argument for oven EF
	o_ef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("O_ef")
	o_ef.setDisplayName("Oven Energy Factor")
	o_ef.setDescription("Oven energy factor determined by DOE test procedures for cooking appliances (DOE 1997).")
	o_ef.setDefaultValue(0.11)
	args << o_ef
	
	#make a boolean argument for has electric ignition
	e_ignition = OpenStudio::Ruleset::OSArgument::makeBoolArgument("e_ignition")
	e_ignition.setDisplayName("Has Electronic Ignition")
	e_ignition.setDescription("For gas/propane cooking ranges with electronic ignition, an extra (40 + 13.3x(#BR)) kWh/yr of electricity will be included.")
	e_ignition.setDefaultValue(false)
	args << e_ignition

	#make a double argument for Occupancy Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Occupancy Energy Multiplier")
	mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	mult.setDefaultValue(1)
	args << mult

	#make a choice argument for which zone to put the space in
	#make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end
	
	#make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
	space_type.setDisplayName("Location")
    space_type.setDescription("Select the space where the cooking range is located")
    space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << space_type

	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097")
	args << monthly_sch

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
	num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
	c_ef = runner.getDoubleArgumentValue("C_ef",user_arguments)
	o_ef = runner.getDoubleArgumentValue("O_ef",user_arguments)
	e_ignition = runner.getBoolArgumentValue("e_ignition",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	
	#Convert num bedrooms to appropriate integer
	num_br = num_br.tr('+','').to_f
	
	#if oef or cef is defined, must be > 0
	if o_ef <= 0
		runner.registerError("Oven energy factor must be greater than zero.")
		return false
	elsif c_ef <= 0
		runner.registerError("Cooktop energy factor must be greater than zero.")
		return false
	end
	
	#Calculate gas range daily energy use
    range_ann_g = ((2.64 + 0.88 * num_br) / c_ef + (0.44 + 0.15 * num_br) / o_ef)*mult # therm/yr
    if e_ignition == true
        range_ann_i = (40 + 13.3 * num_br)*mult #kWh/yr
    else
        range_ann_i = 0
    end
	
    #hard coded convective, radiative, latent, and lost fractions
	range_lat_e = 0.3
	range_conv_e = 0.16
	range_rad_e = 0.24
	range_lost_e = 1 - range_lat_e - range_conv_e - range_rad_e
	range_lat_g = 0.2
	range_conv_g = 0.12
	range_rad_g = 0.18
	range_lost_g = 1 - range_lat_g - range_conv_g - range_rad_g

	obj_name = Constants.ObjectNameCookingRange
	obj_name_e = obj_name + "_" + Constants.FuelTypeElectric
	obj_name_g = obj_name + "_" + Constants.FuelTypeGas
	obj_name_i = obj_name + "_" + Constants.FuelTypeElectric + "_ignition"
	sch = Schedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
    design_level_g = sch.calcDesignLevelGas(range_ann_g/365.0)
    design_level_i = sch.calcDesignLevelElec(range_ann_i/365.0)

	#add range to the selected space
	has_gas_range = 0
	replace_gas_range = 0
	remove_e_range = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add range
			space_equipments_g = spaceType.gasEquipment
			space_equipments_g.each do |space_equipment_g| #check for an existing gas range
				if space_equipment_g.gasEquipmentDefinition.name.get.to_s == obj_name_g
                    has_gas_range = 1
                    runner.registerWarning("This space already has a gas range. The existing gas range will be replaced with the specified gas range.")
                    space_equipment_g.gasEquipmentDefinition.setDesignLevel(design_level_g)
                    sch.setSchedule(space_equipment_g)
                    replace_gas_range = 1
				end
			end
			space_equipments_e = spaceType.electricEquipment
			space_equipments_e.each do |space_equipment_e|
				if space_equipment_e.electricEquipmentDefinition.name.get.to_s == obj_name_e
                    runner.registerWarning("This space already has an electric range. The existing range will be replaced with the the currently selected option.")
                    space_equipment_e.remove
                    remove_e_range = 1
				elsif space_equipment_e.electricEquipmentDefinition.name.get.to_s == obj_name_i
					if e_ignition == true
						space_equipment_e.electricEquipmentDefinition.setDesignLevel(design_level_i)
						sch.setSchedule(space_equipment_e)
					else
						space_equipment_e.remove
					end
				end
			end
			
			if has_gas_range == 0

                has_gas_range = 1
				
				#Add equipment for the range
                rng_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
                rng = OpenStudio::Model::GasEquipment.new(rng_def)
                rng.setName(obj_name_g)
                rng.setSpaceType(spaceType)
                rng_def.setName(obj_name_g)
                rng_def.setDesignLevel(design_level_g)
                rng_def.setFractionRadiant(range_rad_g)
                rng_def.setFractionLatent(range_lat_g)
                rng_def.setFractionLost(range_lost_g)
                sch.setSchedule(rng)
                if e_ignition == true
                    rng_def2 = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                    rng2 = OpenStudio::Model::ElectricEquipment.new(rng_def2)
                    rng2.setName(obj_name_i)
                    rng2.setSpaceType(spaceType)
                    rng_def2.setName(obj_name_i)
                    rng_def2.setDesignLevel(design_level_i)
                    rng_def2.setFractionRadiant(range_rad_e)
                    rng_def2.setFractionLatent(range_lat_e)
                    rng_def2.setFractionLost(range_lost_e)
                    sch.setSchedule(rng2)
                end
			end
		end
	end

    #reporting final condition of model
	if has_gas_range == 1
		if replace_gas_range == 1
			if e_ignition == true
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therms and #{range_ann_i.round} kWhs annual energy consumption.")
			else
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therms annual energy consumption.")
			end
		elsif remove_e_range == 1
			if e_ignition == true
				runner.registerFinalCondition("The existing electric range has been replaced by a gas range with #{range_ann_g.round} therms and #{range_ann_i.round} kWhs annual energy consumption.")
			else
				runner.registerFinalCondition("The existing electric range has been replaced by a gas range with #{range_ann_g.round} therms annual energy consumption.")
			end
		else
			if e_ignition == true
				runner.registerFinalCondition("A gas range has been added with #{range_ann_g.round} therms and #{range_ann_i.round} kWhs annual energy consumption.")
			else
				runner.registerFinalCondition("A gas range has been added with #{range_ann_g.round} therms annual energy consumption.")
			end
		end
	else
		runner.registerFinalCondition("Range was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialCookingRange.new.registerWithApplication
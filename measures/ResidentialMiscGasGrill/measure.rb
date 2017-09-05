require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialGasGrill < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Gas Grill"
  end
  
  def description
    return "Adds (or replaces) a residential gas grill with the specified efficiency and schedule. The grill is assumed to be outdoors. For multifamily buildings, the grill is set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Gas Grill object in OpenStudio/EnergyPlus, we look for a GasEquipment object with the name that denotes it is a residential gas grill. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for Base Energy Use
    base_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("base_energy")
    base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("therm/yr")
    base_energy.setDescription("The national average (Building America Benchmark) energy use.")
    base_energy.setDefaultValue(30)
    args << base_energy

    #make a double argument for Energy Multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult")
    mult.setDisplayName("Energy Multiplier")
    mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
    mult.setDefaultValue(1)
    args << mult
    
    #make a boolean argument for Scale Energy Use
    scale_energy = OpenStudio::Measure::OSArgument::makeBoolArgument("scale_energy",true)
    scale_energy.setDisplayName("Scale Energy Use")
    scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
    scale_energy.setDefaultValue(true)
    args << scale_energy

    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch")
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch")
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch")
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
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)

    #check for valid inputs
    if base_energy < 0
        runner.registerError("Base energy use must be greater than or equal to 0.")
        return false
    end
    if mult < 0
        runner.registerError("Energy multiplier must be greater than or equal to 0.")
        return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end

    tot_gg_ann_g = 0
    msgs = []
    sch = nil
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get unit ffa
        ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
        if ffa.nil?
            return false
        end
        
        unit_obj_name = Constants.ObjectNameGasGrill(unit.name.to_s)
        
        # Get space type
        space_types = Geometry.space_type_hierarchy(File.basename(File.dirname(__FILE__)))
        
        unit_spaces = []
        unit.spaces.each do |space|
          if space.spaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.is_initialized
              next unless space.spaceType.get.standardsSpaceType.get == space_types[0]
            end
          end
          space.gasEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name
            unit_spaces << space
          end
        end
        if unit_spaces.empty?
          unit.spaces.each do |unit_space|
              unit_spaces << unit_space
          end
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit_spaces.uniq, nil, runner, space_types)
        next if space.nil?
    
        # Remove any existing gas grill
        objects_to_remove = []
        space.gasEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.gasEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        if objects_to_remove.size > 0
            runner.registerInfo("Removed existing gas grill from outside.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end
    
        #Calculate annual energy use
        ann_g = base_energy * mult # therm/yr
        
        if scale_energy
            #Scale energy use by num beds and floor area
            constant = ann_g/2
            nbr_coef = ann_g/4/3
            ffa_coef = ann_g/4/1920
            gg_ann_g = constant + nbr_coef * nbeds + ffa_coef * ffa # therm/yr
        else
            gg_ann_g = ann_g # therm/yr
        end
    
        if gg_ann_g > 0
            
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameGasGrill + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailyTherm(gg_ann_g/365.0)
            
            #Add gas equipment for the grill
            gg_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
            gg = OpenStudio::Model::GasEquipment.new(gg_def)
            gg.setName(unit_obj_name)
            gg.setEndUseSubcategory(unit_obj_name)
            gg.setSpace(space)
            gg_def.setName(unit_obj_name)
            gg_def.setDesignLevel(design_level)
            gg_def.setFractionRadiant(0)
            gg_def.setFractionLatent(0)
            gg_def.setFractionLost(1)
            gg.setSchedule(sch.schedule)
            
            msgs << "A gas grill with #{gg_ann_g.round} therms annual energy consumption has been assigned to outside."
            
            tot_gg_ann_g += gg_ann_g
        end
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned gas grills totaling #{tot_gg_ann_g.round} therms annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No gas grill has been assigned.")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialGasGrill.new.registerWithApplication
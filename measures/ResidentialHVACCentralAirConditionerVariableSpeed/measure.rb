# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessVariableSpeedCentralAirConditioner < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Variable-Speed Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a variable-speed central air conditioner along with an on/off supply fan to a unitary air loop. For multifamily buildings, the variable-speed central air conditioner can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
  
    #make a double argument for central ac cooling rated seer
    acCoolingInstalledSEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    acCoolingInstalledSEER.setDisplayName("Rated SEER")
    acCoolingInstalledSEER.setUnits("Btu/W-h")
    acCoolingInstalledSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    acCoolingInstalledSEER.setDefaultValue(24.5)
    args << acCoolingInstalledSEER
    
    #make a double argument for central ac eer
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    acCoolingEER.setDisplayName("EER")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    acCoolingEER.setDefaultValue(19.2)
    args << acCoolingEER

    #make a double argument for central ac eer 2
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer2", true)
    acCoolingEER.setDisplayName("EER 2")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    acCoolingEER.setDefaultValue(18.3)
    args << acCoolingEER
    
    #make a double argument for central ac eer 3
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer3", true)
    acCoolingEER.setDisplayName("EER 3")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the third speed.")
    acCoolingEER.setDefaultValue(16.5)
    args << acCoolingEER
    
    #make a double argument for central ac eer 4
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer4", true)
    acCoolingEER.setDisplayName("EER 4")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the fourth speed.")
    acCoolingEER.setDefaultValue(14.6)
    args << acCoolingEER
    
    #make a double argument for central ac rated shr
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    acSHRRated.setDisplayName("Rated SHR")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    acSHRRated.setDefaultValue(0.98)
    args << acSHRRated
    
    #make a double argument for central ac rated shr 2
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr2", true)
    acSHRRated.setDisplayName("Rated SHR 2")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    acSHRRated.setDefaultValue(0.82)
    args << acSHRRated
    
    #make a double argument for central ac rated shr 3
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr3", true)
    acSHRRated.setDisplayName("Rated SHR 3")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the third speed.")
    acSHRRated.setDefaultValue(0.745)
    args << acSHRRated
    
    #make a double argument for central ac rated shr 4
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr4", true)
    acSHRRated.setDisplayName("Rated SHR 4")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the fourth speed.")
    acSHRRated.setDefaultValue(0.77)
    args << acSHRRated
    
    #make a double argument for central ac capacity ratio
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio", true)
    acCapacityRatio.setDisplayName("Capacity Ratio")
    acCapacityRatio.setDescription("Capacity divided by rated capacity.")
    acCapacityRatio.setDefaultValue(0.36)
    args << acCapacityRatio
    
    #make a double argument for central ac capacity ratio 2
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    acCapacityRatio.setDisplayName("Capacity Ratio 2")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for the second speed.")
    acCapacityRatio.setDefaultValue(0.64)
    args << acCapacityRatio
    
    #make a double argument for central ac capacity ratio 3
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio3", true)
    acCapacityRatio.setDisplayName("Capacity Ratio 3")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for the third speed.")
    acCapacityRatio.setDefaultValue(1.0)
    args << acCapacityRatio

    #make a double argument for central ac capacity ratio 4
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio4", true)
    acCapacityRatio.setDisplayName("Capacity Ratio 4")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for the fourth speed.")
    acCapacityRatio.setDefaultValue(1.16)
    args << acCapacityRatio
    
    #make a double argument for central ac fan speed ratio
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    acFanspeedRatio.setDefaultValue(0.51)
    args << acFanspeedRatio
    
    #make a double argument for central ac fan speed ratio 2
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio2", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio 2")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    acFanspeedRatio.setDefaultValue(0.84)
    args << acFanspeedRatio    
    
    #make a double argument for central ac fan speed ratio 3
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio3", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio 3")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the third speed.")
    acFanspeedRatio.setDefaultValue(1.0)
    args << acFanspeedRatio
    
    #make a double argument for central ac fan speed ratio 4
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio4", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio 4")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the fourth speed.")
    acFanspeedRatio.setDefaultValue(1.19)
    args << acFanspeedRatio
    
    #make a double argument for central ac rated supply fan power
    acSupplyFanPowerRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    acSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    acSupplyFanPowerRated.setUnits("W/cfm")
    acSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    acSupplyFanPowerRated.setDefaultValue(0.14)
    args << acSupplyFanPowerRated
    
    #make a double argument for central ac installed supply fan power
    acSupplyFanPowerInstalled = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    acSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    acSupplyFanPowerInstalled.setUnits("W/cfm")
    acSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    acSupplyFanPowerInstalled.setDefaultValue(0.3)
    args << acSupplyFanPowerInstalled
    
    #make a double argument for central ac crankcase
    acCrankcase = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    acCrankcase.setDisplayName("Crankcase")
    acCrankcase.setUnits("kW")
    acCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    acCrankcase.setDefaultValue(0.0)
    args << acCrankcase

    #make a double argument for central ac crankcase max t
    acCrankcaseMaxT = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_max_temp", true)
    acCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    acCrankcaseMaxT.setUnits("degrees F")
    acCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    acCrankcaseMaxT.setDefaultValue(55.0)
    args << acCrankcaseMaxT
    
    #make a double argument for central ac 1.5 ton eer capacity derate
    acEERCapacityDerateFactor1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    acEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    acEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    acEERCapacityDerateFactor2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    acEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    acEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    acEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    acEERCapacityDerateFactor3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    acEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    acEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    acEERCapacityDerateFactor3ton.setDefaultValue(0.89)
    args << acEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    acEERCapacityDerateFactor4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    acEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    acEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    acEERCapacityDerateFactor4ton.setDefaultValue(0.89)
    args << acEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    acEERCapacityDerateFactor5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    acEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    acEERCapacityDerateFactor5ton.setDefaultValue(0.89)
    args << acEERCapacityDerateFactor5ton
    
    #make a string argument for central air cooling output capacity
    acCoolingOutputCapacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    acCoolingOutputCapacity.setDisplayName("Cooling Capacity")
    acCoolingOutputCapacity.setDescription("The output cooling capacity of the air conditioner. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    acCoolingOutputCapacity.setUnits("tons")
    acCoolingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << acCoolingOutputCapacity    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
  
    acCoolingInstalledSEER = runner.getDoubleArgumentValue("seer",user_arguments)
    acCoolingEER = [runner.getDoubleArgumentValue("eer",user_arguments), runner.getDoubleArgumentValue("eer2",user_arguments), runner.getDoubleArgumentValue("eer3",user_arguments), runner.getDoubleArgumentValue("eer4",user_arguments)]
    acSHRRated = [runner.getDoubleArgumentValue("shr",user_arguments), runner.getDoubleArgumentValue("shr2",user_arguments), runner.getDoubleArgumentValue("shr3",user_arguments), runner.getDoubleArgumentValue("shr4",user_arguments)]
    acCapacityRatio = [runner.getDoubleArgumentValue("capacity_ratio",user_arguments), runner.getDoubleArgumentValue("capacity_ratio2",user_arguments), runner.getDoubleArgumentValue("capacity_ratio3",user_arguments), runner.getDoubleArgumentValue("capacity_ratio4",user_arguments)]
    acFanspeedRatio = [runner.getDoubleArgumentValue("fan_speed_ratio",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio2",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio3",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio4",user_arguments)]
    acSupplyFanPowerRated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    acSupplyFanPowerInstalled = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    acCrankcase = runner.getDoubleArgumentValue("crankcase_capacity",user_arguments)
    acCrankcaseMaxT = runner.getDoubleArgumentValue("crankcase_max_temp",user_arguments)
    acEERCapacityDerateFactor1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton",user_arguments)
    acEERCapacityDerateFactor2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton",user_arguments)
    acEERCapacityDerateFactor3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton",user_arguments)
    acEERCapacityDerateFactor4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton",user_arguments)
    acEERCapacityDerateFactor5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton",user_arguments)
    acEERCapacityDerateFactor = [acEERCapacityDerateFactor1ton, acEERCapacityDerateFactor2ton, acEERCapacityDerateFactor3ton, acEERCapacityDerateFactor4ton, acEERCapacityDerateFactor5ton]
    acOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    unless acOutputCapacity == Constants.SizingAuto
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.to_f,"ton","Btu/h").get
    end 
    
    number_Speeds = 4
    
    # Performance curves

    # NOTE: These coefficients are in IP UNITS
    cOOL_CAP_FT_SPEC = [[3.845135427537, -0.095933272242, 0.000924533273, 0.008939030321, -0.000021025870, -0.000191684744], 
                        [1.902445285801, -0.042809294549, 0.000555959865, 0.009928999493, -0.000013373437, -0.000211453245], 
                        [-3.176259152730, 0.107498394091, -0.000574951600, 0.005484032413, -0.000011584801, -0.000135528854],
                        [1.216308942608, -0.021962441981, 0.000410292252, 0.007362335339, -0.000000025748, -0.000202117724]]
    cOOL_EIR_FT_SPEC = [[-1.400822352, 0.075567798, -0.000589362, -0.024655521, 0.00032690848, -0.00010222178], 
                        [3.278112067, -0.07106453, 0.000468081, -0.014070845, 0.00022267912, -0.00004950051], 
                        [1.183747649, -0.041423179, 0.000390378, 0.021207528, 0.00011181091, -0.00034107189], 
                        [-3.97662986, 0.115338094, -0.000841943, 0.015962287, 0.00007757092, -0.00018579409]]
    cOOL_CAP_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    cOOL_EIR_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    
    static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Cooling Coil
    acRatedAirFlowRate = 315.8 # cfm
    cFM_TON_Rated = HVAC.calc_cfm_ton_rated(acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio)
    coolingEIR = HVAC.calc_cooling_eir(number_Speeds, acCoolingEER, acSupplyFanPowerRated)
    sHR_Rated_Gross = HVAC.calc_shr_rated_gross(number_Speeds, acSHRRated, acSupplyFanPowerRated, cFM_TON_Rated)
    cOOL_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_cooling(number_Speeds, acCoolingInstalledSEER)] * number_Speeds
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameCentralAirConditioner(unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
    
        # Remove existing equipment
        htg_coil = HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, control_zone)

        # _processCurvesDXCooling
        
        clg_coil_stage_data = HVAC.calc_coil_stage_data_cooling(model, acOutputCapacity, number_Speeds, coolingEIR, sHR_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)

        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        clg_coil.setCondenserType("AirCooled")
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(acCrankcase,"kW","W").get)
        clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(acCrankcaseMaxT,"F","C").get)
        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |stage|
            clg_coil.addStage(stage)
        end
          
        # _processSystemFan
        if not htg_coil.nil?
          begin
            furnaceFuelType = HelperMethods.reverse_eplus_fuel_map(htg_coil.fuelType)
          rescue
            furnaceFuelType = Constants.FuelTypeElectric
          end
          obj_name = Constants.ObjectNameFurnaceAndCentralAirConditioner(furnaceFuelType, unit.name.to_s)
        end
        
        fan_power_curve = HVAC.create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)        
        fan_eff_curve = HVAC.create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(HVAC.calculate_fan_efficiency(static, acSupplyFanPowerInstalled))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)
      
        # _processSystemAir
              
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setCoolingCoil(clg_coil)      
        if not htg_coil.nil?
          # Add the existing furnace back in
          air_loop_unitary.setHeatingCoil(htg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0000001) # this is when there is no heating present
        end
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)    
        
        perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
        air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
        perf.setSingleModeOperation(false)
        for speed in 1..number_Speeds
          f = OpenStudio::Model::SupplyAirflowRatioField.fromCoolingRatio(acFanspeedRatio[speed-1])
          perf.addSupplyAirflowRatioField(f)
        end
        
        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode    
        
        air_loop_unitary.addToNode(air_supply_inlet_node)
        
        runner.registerInfo("Added '#{fan.name}' to #{air_loop_unitary.name}' of '#{air_loop.name}'")
        runner.registerInfo("Added '#{clg_coil.name}' to #{air_loop_unitary.name}' of '#{air_loop.name}'")
        unless htg_coil.nil?
          runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        end
        
        air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)
        
        # _processSystemDemandSideAir
        # Demand Side

        # Supply Air
        zone_splitter = air_loop.zoneSplitter
        zone_splitter.setName(obj_name + " zone splitter")
        
        zone_mixer = air_loop.zoneMixer
        zone_mixer.setName(obj_name + " zone mixer")

        diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
        diffuser_living.setName(obj_name + " #{control_zone.name} direct air")
        air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

        air_loop.addBranchForZone(control_zone)
        runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}' of #{unit.name}")

        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, slave_zone)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end
          
        end # slave_zone
      
      end # control_zone
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, acCapacityRatio.join(","))
      unit.setFeature(Constants.SizingInfoHVACCapacityDerateFactorEER, acEERCapacityDerateFactor.join(","))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cFM_TON_Rated.join(","))
      
    end # unit

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessVariableSpeedCentralAirConditioner.new.registerWithApplication
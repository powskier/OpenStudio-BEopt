#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessFurnaceFuel < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Furnace Fuel"
  end
  
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a furnace along with an on/off supply fan to a unitary air loop. For multifamily buildings, the furnace can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A fuel heating coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a string argument for furnace fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeOil
    fuel_display_names << Constants.FuelTypePropane
    fueltype = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
    fueltype.setDisplayName("Fuel Type")
    fueltype.setDescription("Type of fuel used for heating.")
    fueltype.setDefaultValue(Constants.FuelTypeGas)
    args << fueltype  
  
    #make an argument for entering furnace installed afue
    afue = OpenStudio::Measure::OSArgument::makeDoubleArgument("afue",true)
    afue.setDisplayName("Installed AFUE")
    afue.setUnits("Btu/Btu")
    afue.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the furnace, which can be used to account for performance derating or degradation relative to the rated value.")
    afue.setDefaultValue(0.78)
    args << afue

    #make an argument for entering furnace installed supply fan power
    fanpower = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed",true)
    fanpower.setDisplayName("Installed Supply Fan Power")
    fanpower.setUnits("W/cfm")
    fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan for the maximum fan speed under actual operating conditions.")
    fanpower.setDefaultValue(0.5)
    args << fanpower    
    
    #make a string argument for furnace heating output capacity
    furnacecap = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    furnacecap.setDisplayName("Heating Capacity")
    furnacecap.setDescription("The output heating capacity of the furnace. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    furnacecap.setUnits("kBtu/hr")
    furnacecap.setDefaultValue(Constants.SizingAuto)
    args << furnacecap
    
    #make a string argument for distribution system efficiency
    dist_system_eff = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dist_system_eff.setDisplayName("Distribution System Efficiency")
    dist_system_eff.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dist_system_eff.setDefaultValue("NA")
    args << dist_system_eff  
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    furnaceFuelType = runner.getStringArgumentValue("fuel_type",user_arguments)
    furnaceInstalledAFUE = runner.getDoubleArgumentValue("afue",user_arguments)
    furnaceOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    if not furnaceOutputCapacity == Constants.SizingAuto
      furnaceOutputCapacity = UnitConversions.convert(furnaceOutputCapacity.to_f,"kBtu/hr","Btu/hr")
    end
    furnaceInstalledSupplyFanPower = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    dse = runner.getStringArgumentValue("dse",user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end
    
    # _processAirSystem
    
    static = UnitConversions.convert(0.5,"inH2O","Pa") # Pascal

    hir = HVAC.get_furnace_hir(furnaceInstalledAFUE)

    # Parasitic Electricity (Source: DOE. (2007). Technical Support Document: Energy Efficiency Program for Consumer Products: "Energy Conservation Standards for Residential Furnaces and Boilers". www.eere.energy.gov/buildings/appliance_standards/residential/furnaces_boilers.html)
    #             FurnaceParasiticElecDict = {Constants.FuelTypeGas     :  76, # W during operation
    #                                         Constants.FuelTypeOil     : 220}
    #             aux_elec = FurnaceParasiticElecDict[furnaceFuelType]
    aux_elec = 0.0 # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)    

    # Remove boiler hot water loop if it exists
    HVAC.remove_boiler_and_gshp_loops(model, runner)    

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameFurnace(furnaceFuelType, unit.name.to_s)
    
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        # Remove existing equipment
        clg_coil, perf = HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameFurnace, control_zone, true, unit)
        
        # _processSystemHeatingCoil

        htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
        htg_coil.setName(obj_name + " heating coil")
        htg_coil.setGasBurnerEfficiency(dse / hir)
        if furnaceOutputCapacity != Constants.SizingAuto
          htg_coil.setNominalCapacity(UnitConversions.convert(furnaceOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
        end

        htg_coil.setParasiticElectricLoad(aux_elec) # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)
        htg_coil.setParasiticGasLoad(0)
        htg_coil.setFuelType(HelperMethods.eplus_fuel_map(furnaceFuelType))
        
        # _processSystemFan
        if not clg_coil.nil?
          obj_name = Constants.ObjectNameFurnaceAndCentralAirConditioner(furnaceFuelType, unit.name.to_s)
        end

        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(dse * UnitConversions.convert(static / furnaceInstalledSupplyFanPower,"cfm","m^3/s")) # Overall Efficiency of the Supply Fan, Motor and Drive
        fan.setPressureRise(static)
        fan.setMotorEfficiency(dse * 1.0)
        fan.setMotorInAirstreamFraction(1.0)  
      
        # _processSystemAir
        
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setHeatingCoil(htg_coil)
        if not clg_coil.nil?
          # Add the existing DX central air back in
          air_loop_unitary.setCoolingCoil(clg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0000001) # this is when there is no cooling present
        end
        if not perf.nil?
          air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
        end
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0,"F","C"))      
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)

        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode

        air_loop_unitary.addToNode(air_supply_inlet_node)

        runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        unless clg_coil.nil?
          runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
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
      
        HVAC.prioritize_zone_hvac(model, runner, control_zone)
      
        slave_zones.each do |slave_zone|
        
          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameFurnace, slave_zone, false, unit)
        
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")
        
          HVAC.prioritize_zone_hvac(model, runner, slave_zone)
        
        end    
      
      end
      
    end
    
    return true
 
  end #end the run method  
  
end #end the measure

#this allows the measure to be use by the application
ProcessFurnaceFuel.new.registerWithApplication
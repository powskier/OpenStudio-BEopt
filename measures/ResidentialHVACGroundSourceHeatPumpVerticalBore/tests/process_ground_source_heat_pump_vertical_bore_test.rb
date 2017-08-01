require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessGroundSourceHeatPumpVerticalBoreTest < MiniTest::Test

  def test_error_no_weather
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_FB_UA.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Model has not been assigned a weather file.")    
  end

  def test_new_construction_fbsmt_cop_3_6_eer_16_6_autosize
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_new_construction_fbsmt_cop_3_6_eer_16_6
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["supplemental_capacity"] = "20"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end

  def test_hardsized_bore_holes_1
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_hardsized_bore_holes_2
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "2"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end

  def test_hardsized_bore_holes_3
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_hardsized_bore_holes_4
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "4"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_hardsized_bore_holes_5
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "5"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_hardsized_bore_depth
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_depth"] = "150"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end    
  
  def test_hardsized_bore_holes_and_depth
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_holes"] = "1"
    args_hash["bore_depth"] = "150"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_new_construction_frac_glycol_zero
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["frac_glycol"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.0}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6, 1)
  end

  def test_new_construction_pipe_1_in
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["pipe_size"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end

  def test_new_construction_pipe_1_25_in
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["pipe_size"] = 1.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_new_construction_bore_config_L
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["bore_config"] = Constants.BoreConfigLconfig
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end

  def test_retrofit_replace_ashp
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end    
  
  def test_retrofit_replace_ashp2
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXMultiSpeed"=>1, "CoilHeatingDXMultiSpeedStageData"=>2, "CoilCoolingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "UnitarySystemPerformanceMultispeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP2.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end    
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end    
  
  def test_retrofit_replace_central_air_conditioner2
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "UnitarySystemPerformanceMultispeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC2.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end    
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end    
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end  
  
  def test_retrofit_replace_boiler
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end    
  
  def test_retrofit_replace_mshp
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"FanOnOff"=>2, "AirConditionerVariableRefrigerantFlow"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end  
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end    
  
  def test_retrofit_replace_furnace_central_air_conditioner2
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "UnitarySystemPerformanceMultispeed"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC2.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end    
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>2, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end    
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end    
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 11)
  end    
  
  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end    
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end  
  
  def test_retrofit_replace_gshp_vert_bore
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_GSHPVertBore.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>num_units, "CoilHeatingWaterToAirHeatPumpEquationFit"=>num_units, "CoilCoolingWaterToAirHeatPumpEquationFit"=>num_units, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>num_units, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>num_units*2, "AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*6)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    expected_num_del_objects = {}
    expected_num_new_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>num_units, "CoilHeatingWaterToAirHeatPumpEquationFit"=>num_units, "CoilCoolingWaterToAirHeatPumpEquationFit"=>num_units, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>num_units, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>num_units, "AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units}
    expected_values = {"HeatingCOP"=>3.65, "CoolingCOP"=>5.36, "CoolingNominalCapacity"=>10550.55, "HeatingNominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>76.66, "hvac_priority"=>1, "GlycolFrac"=>0.3}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*5)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessGroundSourceHeatPumpVerticalBore.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessGroundSourceHeatPumpVerticalBore.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "AirLoopHVACUnitarySystem"
                assert_in_epsilon(expected_values["MaximumSupplyAirTemperature"], new_object.maximumSupplyAirTemperature.get, 0.01)
            elsif obj_type == "CoilHeatingWaterToAirHeatPumpEquationFit"
                assert_in_epsilon(expected_values["HeatingCOP"], new_object.ratedHeatingCoefficientofPerformance, 0.01)
                if new_object.ratedHeatingCapacity.is_initialized
                    assert_in_epsilon(expected_values["HeatingNominalCapacity"], new_object.ratedHeatingCapacity.get, 0.01)
                end
            elsif obj_type == "CoilCoolingWaterToAirHeatPumpEquationFit"
                assert_in_epsilon(expected_values["CoolingCOP"], new_object.ratedCoolingCoefficientofPerformance, 0.01)
                if new_object.ratedTotalCoolingCapacity.is_initialized
                    assert_in_epsilon(expected_values["CoolingNominalCapacity"], new_object.ratedTotalCoolingCapacity.get, 0.01)
                end
            elsif obj_type == "PlantLoop"
              assert_in_epsilon(expected_values["GlycolFrac"], new_object.glycolConcentration * 0.01, 0.01)            
            end
        end
    end
    
    return model
  end  
  
end

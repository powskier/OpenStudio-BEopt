require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterDistributionTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end
  
  def osm_geo_beds_loc_tankwh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank.osm"
  end

  def osm_geo_beds_loc_tankwh_fixtures
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank_HWFixtures.osm"
  end
  
  def osm_geo_multifamily_3_units_beds_loc_tankwh
    return "multifamily_3_units_Beds_Baths_Denver_ElecWHtank_HWFixtures.osm"
  end

  def test_new_construction_case1_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_case1_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>27.33, "SinkDailyWater_gpd"=>23.05, "BathDailyWater_gpd"=>6.93, "InternalLoadAnnual_MBtu"=>1.207, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case2_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>26.91, "SinkDailyWater_gpd"=>22.80, "BathDailyWater_gpd"=>6.85, "InternalLoadAnnual_MBtu"=>1.171, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case2_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>26.34, "SinkDailyWater_gpd"=>20.55, "BathDailyWater_gpd"=>6.78, "InternalLoadAnnual_MBtu"=>0.904, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case3_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>25.15, "SinkDailyWater_gpd"=>22.60, "BathDailyWater_gpd"=>6.22, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case3_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>24.40, "SinkDailyWater_gpd"=>21.40, "BathDailyWater_gpd"=>6.15, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case4_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>24.16, "SinkDailyWater_gpd"=>20.62, "BathDailyWater_gpd"=>6.19, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case4_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>23.44, "SinkDailyWater_gpd"=>19.53, "BathDailyWater_gpd"=>6.13, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case5_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>26.45, "SinkDailyWater_gpd"=>22.46, "BathDailyWater_gpd"=>6.74, "InternalLoadAnnual_MBtu"=>1.136, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case5_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>26.07, "SinkDailyWater_gpd"=>20.91, "BathDailyWater_gpd"=>6.71, "InternalLoadAnnual_MBtu"=>0.900, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case6_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>23.74, "SinkDailyWater_gpd"=>20.32, "BathDailyWater_gpd"=>5.98, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case6_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>23.04, "SinkDailyWater_gpd"=>19.24, "BathDailyWater_gpd"=>5.91, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case7_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>47.95, "SinkDailyWater_gpd"=>40.45, "BathDailyWater_gpd"=>28.56, "InternalLoadAnnual_MBtu"=>8.904, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_case7_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>33.28, "SinkDailyWater_gpd"=>25.33, "BathDailyWater_gpd"=>14.29, "InternalLoadAnnual_MBtu"=>4.542, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case8_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.85, "SinkDailyWater_gpd"=>22.58, "BathDailyWater_gpd"=>9.57, "InternalLoadAnnual_MBtu"=>2.085, "RecircPumpAnnual_kWh"=>2.03, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_case8_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>25.55, "SinkDailyWater_gpd"=>18.62, "BathDailyWater_gpd"=>6.67, "InternalLoadAnnual_MBtu"=>1.599, "RecircPumpAnnual_kWh"=>1.65, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case9_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>46.92, "SinkDailyWater_gpd"=>38.81, "BathDailyWater_gpd"=>28.41, "InternalLoadAnnual_MBtu"=>6.714, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_case9_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>32.38, "SinkDailyWater_gpd"=>23.78, "BathDailyWater_gpd"=>14.14, "InternalLoadAnnual_MBtu"=>3.425, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case10_r0
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>27.83, "SinkDailyWater_gpd"=>20.85, "BathDailyWater_gpd"=>9.42, "InternalLoadAnnual_MBtu"=>1.572, "RecircPumpAnnual_kWh"=>2.03, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_case10_r2
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>24.55, "SinkDailyWater_gpd"=>16.99, "BathDailyWater_gpd"=>6.53, "InternalLoadAnnual_MBtu"=>1.206, "RecircPumpAnnual_kWh"=>1.65, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_case11_interior
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end

  def test_new_construction_case11_exterior
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialPEX
    args_hash["dist_layout"] = Constants.PipeTypeHomeRun
    args_hash["space"] = Constants.LocationExterior
    args_hash["recirc_type"] = Constants.RecircTypeDemand
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_retrofit_add_insulation
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    model = _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {"WaterUseEquipment"=>3, "OtherEquipment"=>1}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>27.33, "SinkDailyWater_gpd"=>23.05, "BathDailyWater_gpd"=>6.93, "InternalLoadAnnual_MBtu"=>1.207, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_remove_insulation
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>27.33, "SinkDailyWater_gpd"=>23.05, "BathDailyWater_gpd"=>6.93, "InternalLoadAnnual_MBtu"=>1.207, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    model = _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {"WaterUseEquipment"=>3, "OtherEquipment"=>1}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_add_recirc
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    model = _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    expected_num_del_objects = {"WaterUseEquipment"=>3, "OtherEquipment"=>1}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>47.95, "SinkDailyWater_gpd"=>40.45, "BathDailyWater_gpd"=>28.56, "InternalLoadAnnual_MBtu"=>8.904, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_remove_recirc
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeTimer
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>47.95, "SinkDailyWater_gpd"=>40.45, "BathDailyWater_gpd"=>28.56, "InternalLoadAnnual_MBtu"=>8.904, "RecircPumpAnnual_kWh"=>193, "RecircPumpFractionLost"=>0}
    model = _test_measure(osm_geo_beds_loc_tankwh_fixtures, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["recirc_type"] = Constants.RecircTypeNone
    expected_num_del_objects = {"WaterUseEquipment"=>3, "OtherEquipment"=>1, "ElectricEquipment"=>1}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleRuleset"=>1, "OtherEquipmentDefinition"=>1, "OtherEquipment"=>1}
    expected_values = {"ShowerDailyWater_gpd"=>28.01, "SinkDailyWater_gpd"=>24.98, "BathDailyWater_gpd"=>7.01, "InternalLoadAnnual_MBtu"=>1.553, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)  
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3*num_units, "WaterUseEquipment"=>3*num_units, "ScheduleRuleset"=>num_units, "OtherEquipmentDefinition"=>num_units, "OtherEquipment"=>num_units}
    expected_values = {"ShowerDailyWater_gpd"=>79.36, "SinkDailyWater_gpd"=>70.78, "BathDailyWater_gpd"=>19.86, "InternalLoadAnnual_MBtu"=>4.391, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_retrofit
    num_units = 3
    args_hash = {}
    args_hash["pipe_mat"] = Constants.MaterialCopper
    args_hash["dist_layout"] = Constants.PipeTypeTrunkBranch
    args_hash["space"] = Constants.LocationInterior
    args_hash["recirc_type"] = Constants.RecircTypeNone
    args_hash["dist_ins"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3*num_units, "WaterUseEquipment"=>3*num_units, "ScheduleRuleset"=>num_units, "OtherEquipmentDefinition"=>num_units, "OtherEquipment"=>num_units}
    expected_values = {"ShowerDailyWater_gpd"=>79.36, "SinkDailyWater_gpd"=>70.78, "BathDailyWater_gpd"=>19.86, "InternalLoadAnnual_MBtu"=>4.391, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash["dist_ins"] = 2
    expected_num_del_objects = {"WaterUseEquipment"=>3*num_units, "OtherEquipment"=>num_units}
    expected_num_new_objects = {"WaterUseEquipmentDefinition"=>3*num_units, "WaterUseEquipment"=>3*num_units, "ScheduleRuleset"=>num_units, "OtherEquipmentDefinition"=>num_units, "OtherEquipment"=>num_units}
    expected_values = {"ShowerDailyWater_gpd"=>77.28, "SinkDailyWater_gpd"=>64.98, "BathDailyWater_gpd"=>19.66, "InternalLoadAnnual_MBtu"=>3.411, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2*num_units)
  end

  def test_argument_error_dist_ins_negative
    args_hash = {}
    args_hash["dist_ins"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh_fixtures, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Insulation Nominal R-Value must be greater than or equal to 0.")
  end
  
  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_location
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mains water temperature has not been set.")
  end

  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not find plant loop.")
  end
  
  def test_error_missing_hot_water_fixtures
    args_hash = {}
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Residential Hot Water Fixture measure must be run prior to running this measure.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterDistribution.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterDistribution.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

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

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    assert(result.finalCondition.is_initialized)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"InternalLoadAnnual_MBtu"=>0, "RecircPumpAnnual_kWh"=>0, "RecircPumpFractionLost"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "OtherEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["InternalLoadAnnual_MBtu"] += OpenStudio.convert(full_load_hrs * new_object.otherEquipmentDefinition.designLevel.get * new_object.multiplier, "Wh", "MBtu").get
            elsif obj_type == "ElectricEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["RecircPumpAnnual_kWh"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
                actual_values["RecircPumpFractionLost"] += new_object.electricEquipmentDefinition.fractionLost
            end
        end
    end
    assert_in_epsilon(expected_values["InternalLoadAnnual_MBtu"], actual_values["InternalLoadAnnual_MBtu"], 0.01)
    assert_in_epsilon(expected_values["RecircPumpAnnual_kWh"], actual_values["RecircPumpAnnual_kWh"], 0.01)
    assert_in_epsilon(expected_values["RecircPumpFractionLost"], actual_values["RecircPumpFractionLost"], 0.01)
    
    actual_values = {"ShowerDailyWater_gpd"=>0, "SinkDailyWater_gpd"=>0, "BathDailyWater_gpd"=>0}
    final_objects.each do |obj_type, final_object|
        next if not final_object.respond_to?("to_#{obj_type}")
        final_object = final_object.public_send("to_#{obj_type}").get
            if obj_type == "WaterUseEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, final_object.flowRateFractionSchedule.get)
                actual_hw_gpd = OpenStudio.convert(full_load_hrs * final_object.waterUseEquipmentDefinition.peakFlowRate * final_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
                if final_object.name.to_s.start_with?(Constants.ObjectNameShower)
                    actual_values["ShowerDailyWater_gpd"] += actual_hw_gpd
                elsif final_object.name.to_s.start_with?(Constants.ObjectNameSink)
                    actual_values["SinkDailyWater_gpd"] += actual_hw_gpd
                elsif final_object.name.to_s.start_with?(Constants.ObjectNameBath)
                    actual_values["BathDailyWater_gpd"] += actual_hw_gpd
                end
            end
    end
    assert_in_epsilon(expected_values["ShowerDailyWater_gpd"], actual_values["ShowerDailyWater_gpd"], 0.01)
    assert_in_epsilon(expected_values["SinkDailyWater_gpd"], actual_values["SinkDailyWater_gpd"], 0.01)
    assert_in_epsilon(expected_values["BathDailyWater_gpd"], actual_values["BathDailyWater_gpd"], 0.01)
    
    return model
  end
  
end
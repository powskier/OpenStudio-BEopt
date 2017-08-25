require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterFixturesTest < MiniTest::Test

  def osm_geo
    return "SFD_2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc_tankwh
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTank.osm"
  end

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.0
    args_hash["bath_mult"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_new_construction_standard
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>445.1, "HotWater_gpd"=>60, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_new_construction_varying_mults
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.5
    args_hash["bath_mult"] = 1.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>2, "OtherEquipment"=>2, "WaterUseEquipmentDefinition"=>2, "WaterUseEquipment"=>2, "ScheduleFixedInterval"=>2, "ScheduleConstant"=>2}
    expected_values = {"Annual_kwh"=>107.7, "HotWater_gpd"=>23, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_new_construction_basement
    args_hash = {}
    args_hash["space"] = "Space: #{Constants.FinishedBasementSpace}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>445.1, "HotWater_gpd"=>60, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>445.1, "HotWater_gpd"=>60, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.5
    args_hash["bath_mult"] = 1.5
    expected_num_del_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>2, "OtherEquipment"=>2, "WaterUseEquipmentDefinition"=>2, "WaterUseEquipment"=>2, "ScheduleFixedInterval"=>2, "ScheduleConstant"=>2}
    expected_values = {"Annual_kwh"=>107.7, "HotWater_gpd"=>23, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>445.1, "HotWater_gpd"=>60, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.0
    args_hash["bath_mult"] = 0.0
    expected_num_del_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1, 1)
  end
  
  def test_argument_error_shower_mult_negative
    args_hash = {}
    args_hash["shower_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Shower hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_argument_error_sink_mult_negative
    args_hash = {}
    args_hash["sink_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Sink hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_argument_error_bath_mult_negative
    args_hash = {}
    args_hash["bath_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Bath hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not find plant loop.")
  end

  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>num_units*3, "OtherEquipment"=>num_units*3, "WaterUseEquipmentDefinition"=>num_units*3, "WaterUseEquipment"=>num_units*3, "ScheduleFixedInterval"=>num_units*3, "ScheduleConstant"=>num_units*3}
    expected_values = {"Annual_kwh"=>num_units*445.1, "HotWater_gpd"=>num_units*60, "Space"=>args_hash["space"]}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver_ElecWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units)
  end

  def test_single_family_attached_new_construction_finished_basement
    num_units = 4
    args_hash = {}
    args_hash["space"] = "Space: #{Constants.FinishedBasementSpace}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>445.1, "HotWater_gpd"=>60, "Space"=>args_hash["space"]}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver_ElecWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units-1)
  end  
  
  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>num_units*3, "OtherEquipment"=>num_units*3, "WaterUseEquipmentDefinition"=>num_units*3, "WaterUseEquipment"=>num_units*3, "ScheduleFixedInterval"=>num_units*3, "ScheduleConstant"=>num_units*3}
    expected_values = {"Annual_kwh"=>num_units*445.1, "HotWater_gpd"=>num_units*60, "Space"=>args_hash["space"]}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver_ElecWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units)
  end
  
  def test_sfd_multi_zone_auto
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>370.9, "HotWater_gpd"=>50, "SpaceType"=>"Space Type: #{Constants.BathroomSpaceType}"}
    _test_measure("SFD_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver_GasWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_sfd_multi_zone_kitchen
    args_hash = {}
    args_hash["space"] = "Space Type: #{Constants.KitchenSpaceType}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>3, "OtherEquipment"=>3, "WaterUseEquipmentDefinition"=>3, "WaterUseEquipment"=>3, "ScheduleFixedInterval"=>3, "ScheduleConstant"=>3}
    expected_values = {"Annual_kwh"=>370.9, "HotWater_gpd"=>50, "SpaceType"=>args_hash["space"]}
    _test_measure("SFD_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver_GasWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_mf_multi_zone_auto
    num_units = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>num_units*3, "OtherEquipment"=>num_units*3, "WaterUseEquipmentDefinition"=>num_units*3, "WaterUseEquipment"=>num_units*3, "ScheduleFixedInterval"=>num_units*3, "ScheduleConstant"=>num_units*3}
    expected_values = {"Annual_kwh"=>num_units*370.9, "HotWater_gpd"=>num_units*50, "SpaceType"=>"Space Type: #{Constants.BathroomSpaceType}"}
    _test_measure("MF_2units_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver_GasWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_mf_multi_zone_kitchen
    num_units = 2
    args_hash = {}
    args_hash["space"] = "Space Type: #{Constants.KitchenSpaceType}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"OtherEquipmentDefinition"=>num_units*3, "OtherEquipment"=>num_units*3, "WaterUseEquipmentDefinition"=>num_units*3, "WaterUseEquipment"=>num_units*3, "ScheduleFixedInterval"=>num_units*3, "ScheduleConstant"=>num_units*3}
    expected_values = {"Annual_kwh"=>num_units*370.9, "HotWater_gpd"=>num_units*50, "SpaceType"=>args_hash["space"]}
    _test_measure("MF_2units_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver_GasWHTank.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterFixtures.new
    
    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterFixtures.new

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

    # show the output
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    assert(result.finalCondition.is_initialized)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["WaterUseConnections", "Node", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>[], "SpaceType"=>[]}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "OtherEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, new_object.schedule.get)
                actual_values["Annual_kwh"] += OpenStudio.convert(full_load_hrs * new_object.otherEquipmentDefinition.designLevel.get * new_object.multiplier, "Wh", "kWh").get
                actual_values["Space"] << new_object.space.get.name.to_s
                actual_values["SpaceType"] << new_object.space.get.spaceType.get.standardsSpaceType.get
            elsif obj_type == "WaterUseEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, new_object.flowRateFractionSchedule.get)
                actual_values["HotWater_gpd"] += OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
                actual_values["Space"] << new_object.space.get.name.to_s
            end
        end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)
    assert_in_epsilon(expected_values["HotWater_gpd"], actual_values["HotWater_gpd"], 0.01)
    if not expected_values["Space"].nil?
        assert_equal(1, actual_values["Space"].uniq.size)
        assert_equal(expected_values["Space"], "Space: #{actual_values["Space"][0]}")
    end
    if not expected_values["SpaceType"].nil?
        assert_equal(1, actual_values["SpaceType"].uniq.size)
        assert_equal(expected_values["SpaceType"], "Space Type: #{actual_values["SpaceType"][0]}")
    end

    return model
  end
  
end

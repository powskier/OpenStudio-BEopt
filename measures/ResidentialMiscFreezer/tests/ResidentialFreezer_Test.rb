require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialFreezerTest < MiniTest::Test

  def osm_geo
    return "SFD_2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def test_new_construction_none1
    # Using rated annual consumption
    args_hash = {}
    args_hash["freezer_E"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_none2
    # Using energy multiplier
    args_hash = {}
    args_hash["mult"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_ef_12
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_mult_0_95
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["mult"] = 0.95
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>888.25, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_mult_1_05
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["mult"] = 1.05
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>981.75, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["space"] = "Space: #{Constants.FinishedBasementSpace}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["freezer_E"] = 417.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>417.0, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["freezer_E"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_argument_error_freezer_E_negative
    args_hash = {}
    args_hash["freezer_E"] = -1.0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated annual consumption must be greater than or equal to 0.")
  end
  
  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Occupancy energy multiplier must be greater than or equal to 0.")
  end
  
  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
  
  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
    
  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end

  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>num_units*935.0, "Space"=>args_hash["space"]}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units)
  end
  
  def test_single_family_attached_new_construction_finished_basement
    num_units = 4
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["space"] = "Space: #{Constants.FinishedBasementSpace}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units-1)
  end 

  def test_single_family_attached_new_construction_unfinished_basement
    num_units = 4
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    args_hash["space"] = "Space: #{Constants.UnfinishedBasementSpace}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>935.0, "Space"=>args_hash["space"]}
    _test_measure("SFA_4units_1story_UB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units-1)
  end  
  
  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    args_hash["freezer_E"] = 935.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipment"=>num_units, "ElectricEquipmentDefinition"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>num_units*935.0, "Space"=>args_hash["space"]}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units)
  end
  
  def test_sfd_multi_zone_auto
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>1, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1}
    expected_values = {"Annual_kwh"=>935.0, "SpaceType"=>"Space Type: #{Constants.GarageSpaceType}"}
    _test_measure("SFD_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_sfd_multi_zone_living
    args_hash = {}
    args_hash["space"] = "Space Type: #{Constants.LivingSpaceType}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>1, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1}
    expected_values = {"Annual_kwh"=>935.0, "SpaceType"=>args_hash["space"]}
    _test_measure("SFD_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_mf_multi_zone_auto
    num_units = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>1, "ElectricEquipment"=>2, "ElectricEquipmentDefinition"=>2}
    expected_values = {"Annual_kwh"=>num_units*935.0, "SpaceType"=>"Space Type: #{Constants.GarageSpaceType}"}
    _test_measure("MF_2units_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_mf_multi_zone_living
    num_units = 2
    args_hash = {}
    args_hash["space"] = "Space Type: #{Constants.LivingSpaceType}"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>1, "ElectricEquipment"=>2, "ElectricEquipmentDefinition"=>2}
    expected_values = {"Annual_kwh"=>num_units*935.0, "SpaceType"=>args_hash["space"]}
    _test_measure("MF_2units_Multizone_2story_SL_UA_GRG_2Bed_2Bath_1Kitchen_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialFreezer.new

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialFreezer.new

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
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"Annual_kwh"=>0, "Space"=>[], "SpaceType"=>[]}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ElectricEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, new_object.schedule.get)
                actual_values["Annual_kwh"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
                actual_values["Space"] << new_object.space.get.name.to_s
                actual_values["SpaceType"] << new_object.space.get.spaceType.get.standardsSpaceType.get
            end
        end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)
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

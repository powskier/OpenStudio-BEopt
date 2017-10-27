require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessHVACSeasonsTest < MiniTest::Test
  
  def test_use_hsp_seasons
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_single_family_attached_new_construction_custom_seasons
    num_units = 4
    args_hash = {}
    args_hash["use_hsp_seasons"] = "false"
    args_hash["heating_start_month"] = "Mar"
    args_hash["cooling_start_month"] = "May"
    args_hash["cooling_end_month"] = "Sep"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"heating_season"=>"0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1", "cooling_season"=>"0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0"}
    _test_measure("SFA_4units_1story_UB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_multifamily_new_construction_custom_seasons
    num_units = 8
    args_hash = {}
    args_hash["use_hsp_seasons"] = "false"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"heating_season"=>"1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1", "cooling_season"=>"1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1"}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  private
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessHVACSeasons.new

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
    
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end
    
    model.getBuildingUnits.each do |unit|
      if unit.getFeatureAsString(Constants.SeasonHeating).is_initialized
        assert_equal(expected_values["heating_season"], unit.getFeatureAsString(Constants.SeasonHeating).get)
      end
      if unit.getFeatureAsString(Constants.SeasonCooling).is_initialized
        assert_equal(expected_values["cooling_season"], unit.getFeatureAsString(Constants.SeasonCooling).get)
      end
    end
    
    return model
  end  
  
end

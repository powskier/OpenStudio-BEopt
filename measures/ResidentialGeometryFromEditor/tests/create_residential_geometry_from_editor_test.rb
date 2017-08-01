require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialGeometryFromEditor_Test < MiniTest::Unit::TestCase

  def test_error_empty_floorplan_path
    args_hash = {}
    args_hash["floorplan_path"] = ""
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Empty floorplan path was entered.")    
  end

  def test_error_invalid_floorplan_path
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "floorpaln.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot find floorplan path '#{args_hash["floorplan_path"]}'.")    
  end

  def test_error_unexpected_space_type_name
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "unexpected_space_type_name.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Unexpected space type name 'graage'.")    
  end
  
  def test_error_mix_of_finished_and_unfinished_spaces_in_a_zone
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "mix_of_spaces_in_a_zone.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "'Thermal Zone 1' has a mix of finished and unfinished spaces.")    
  end
  
  def test_error_empty_floorplan
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "empty.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot load floorplan from '#{args_hash["floorplan_path"]}'.")    
  end
  
  def test_no_spaces_assigned_to_zones
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "no_spaces_assigned_to_zones.json")
    expected_num_del_objects = {}
    expected_num_new_objects = {"Building"=>1, "Surface"=>40, "Space"=>4, "SpaceType"=>3, "ThermalZone"=>3, "BuildingUnit"=>1}
    expected_values = {}
    model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_simple_floorplan_unfinished_attic
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFD_UA.json")
    expected_num_del_objects = {}
    expected_num_new_objects = {"Building"=>1, "Surface"=>40, "Space"=>4, "SpaceType"=>3, "ThermalZone"=>3, "BuildingUnit"=>1}
    expected_values = {}
    model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_simple_floorplan_finished_attic
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFD_FA.json")
    expected_num_del_objects = {}
    expected_num_new_objects = {"Building"=>1, "Surface"=>40, "Space"=>4, "SpaceType"=>2, "ThermalZone"=>2, "BuildingUnit"=>1}
    expected_values = {}
    model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_single_family_attached
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFA_2unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = {"Building"=>1, "Surface"=>75, "Space"=>8, "SpaceType"=>3, "ThermalZone"=>6, "BuildingUnit"=>2}
    expected_values = {}
    model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_4unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = {"Building"=>1, "Surface"=>24, "Space"=>4, "SpaceType"=>1, "ThermalZone"=>4, "BuildingUnit"=>4}
    expected_values = {}
    model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  # def test_multifamily_with_corridor
    # args_hash = {}
    # args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_corr_12unit.json")
    # expected_num_del_objects = {}
    # expected_num_new_objects = {"Building"=>1, "Surface"=>102, "Space"=>14, "SpaceType"=>2, "ThermalZone"=>13, "BuildingUnit"=>12}
    # expected_values = {}
    # model = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  # end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialGeometryFromEditor.new

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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ResidentialGeometryFromEditor.new

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
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["PortList", "ZoneHVACEquipmentList", "Node", "SizingZone"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end

    # save the model to test output directory
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{File.basename(args_hash["floorplan_path"]).gsub(".json","")}" + ".osm")
    # model.save(output_file_path,true)
    
    return model
  end

end

require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialNeighborsTest < MiniTest::Test
  
  def test_error_invalid_neighbor_offset
    args_hash = {}
    args_hash["left_offset"] = -10
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Neighbor offsets must be greater than or equal to 0.")    
  end
  
  def test_not_applicable_no_surfaces
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No surfaces found to copy for neighboring buildings.")
  end
  
  def test_not_applicable_no_neighbors
    args_hash = {}
    args_hash["left_offset"] = 0
    args_hash["right_offset"] = 0    
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No neighbors to be added.")
  end  
  
  def test_copy_all_surfaces
    surfaces_per_neighbor = 12
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)  
  end
    
  def test_house_and_neighbors_have_overhangs
    surfaces_per_neighbor = 12
    num_neighbors = 2  
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Overhangs.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors) 
  end  

  def test_house_and_neighbors_have_eaves
    surfaces_per_neighbor = 12
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors+6*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Eaves.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors+6*num_neighbors)
  end
  
  def test_retrofit_replace
    surfaces_per_neighbor = 12
    num_neighbors = 4
    args_hash = {}
    args_hash["back_offset"] = 10
    args_hash["front_offset"] = 10
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)
    args_hash = {}
    args_hash["left_offset"] = 20
    expected_num_del_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*2, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*2+1)
  end
  
  def test_single_family_attached_new_construction
    surfaces_per_neighbor = 26
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    _test_measure("SFA_4units_1story_SL_UA_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)
  end

  def test_single_family_attached_new_construction_offset
    surfaces_per_neighbor = 32
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    _test_measure("SFA_4units_1story_SL_UA_Offset_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)
  end  
  
  def test_multifamily_new_construction
    surfaces_per_neighbor = 32
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    _test_measure("MF_8units_1story_SL_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)
  end
  
  def test_multifamily_new_construction_inset
    surfaces_per_neighbor = 54
    num_neighbors = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>surfaces_per_neighbor*num_neighbors, "ShadingSurfaceGroup"=>1}
    expected_values = {}
    _test_measure("MF_8units_1story_SL_Inset_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, surfaces_per_neighbor*num_neighbors)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialNeighbors.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = CreateResidentialNeighbors.new

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

    # show_output(result)

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
    
    return model
  end
  
end

require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialEavesTest < MiniTest::Test
=begin
  def test_gable_roof_garage_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>10, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
# =end
# =begin
  def test_geometry_editor
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>0, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
=end
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialEaves.new

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
    measure = CreateResidentialEaves.new

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
    
    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/SFD_UA.osm")
    model.save(output_file_path,true)    
    
    show_output(result)

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
            if obj_type == "ShadingSurface"
                l, w, h = Geometry.get_surface_dimensions(new_object)
                if l < w
                  next if OpenStudio::convert(l,"m","ft").get > 5
                  assert_in_epsilon(expected_values["eaves_depth"], OpenStudio::convert(l,"m","ft").get, 0.01)
                else
                  next if OpenStudio::convert(w,"m","ft").get > 5
                  assert_in_epsilon(expected_values["eaves_depth"], OpenStudio::convert(w,"m","ft").get, 0.01)
                end
            end
        end
    end
    
    return model
  end
  
end

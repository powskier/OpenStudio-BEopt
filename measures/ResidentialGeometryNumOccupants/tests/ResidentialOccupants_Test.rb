require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class AddResidentialOccupantsTest < MiniTest::Test

  def osm_geo
    return "SFD_2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def test_new_construction_none
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_occ"] = "0"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"NumOccupants"=>0}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, 2)
  end

  def test_new_construction_auto
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_occ"] = Constants.Auto
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>2.64, "SpaceType"=>1}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, 2)
  end
  
  def test_new_construction_fixed_3
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_occ"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>3, "SpaceType"=>1}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, 2)
  end
  
  def test_retrofit_replace
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_occ"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>3, "SpaceType"=>1}
    model = _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, 2)
    args_hash = {}
    args_hash["num_occ"] = "2"
    expected_num_del_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>2, "SpaceType"=>1}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces+num_finished_spaces, 2)
  end

  def test_retrofit_remove
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_occ"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>3, "SpaceType"=>1}
    model = _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, 2)
    args_hash = {}
    args_hash["num_occ"] = "0"
    expected_num_del_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_num_new_objects = {}
    expected_values = {"NumOccupants"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces+num_finished_spaces, 2)
  end

  def test_argument_error_num_occ_bad_string
    args_hash = {}
    args_hash["num_occ"] = "hello"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
  end
  
  def test_argument_error_num_occ_negative
    args_hash = {}
    args_hash["num_occ"] = "-1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
  end
  
  def test_argument_error_occ_gain_negative
    args_hash = {}
    args_hash["occ_gain"] = "-1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Internal gains cannot be negative.")
  end
  
  def test_argument_error_sens_frac_negative
    args_hash = {}
    args_hash["sens_frac"] = "-1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Sensible fraction must be greater than or equal to 0 and less than or equal to 1.")
  end
  
  def test_argument_error_lat_frac_negative
    args_hash = {}
    args_hash["lat_frac"] = "-1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Latent fraction must be greater than or equal to 0 and less than or equal to 1.")
  end
  
  def test_argument_error_lat_frac_sens_frac_equal_one
    args_hash = {}
    args_hash["lat_frac"] = "0.5"
    args_hash["sens_frac"] = "0.51"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Sum of sensible and latent fractions must be less than or equal to 1.")
  end

  def test_argument_error_num_occ_incorrect_num_elements
    args_hash = {}
    args_hash["num_occ"] = "2, 3, 4"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of occupant elements specified inconsistent with number of multifamily units defined in the model.")
  end

  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end  

  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
    
  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end

  def test_single_family_attached_new_construction
    num_units = 4
    num_finished_spaces = num_units*2
    args_hash = {}
    args_hash["num_occ"] = "1, 2, 3, auto"
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>9.39, "SpaceType"=>1}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_finished_spaces, num_finished_spaces)
  end

  def test_multifamily_new_construction
    num_units = 8
    num_finished_spaces = num_units
    args_hash = {}
    args_hash["num_occ"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>3*num_units, "SpaceType"=>1}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units, num_units*2)
  end
  
  def test_sfd_multi_zone
    num_living_spaces = 4
    num_bedroom_spaces = 2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_living_spaces+num_bedroom_spaces, "People"=>num_living_spaces+num_bedroom_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>2.05, "SpaceType"=>2}
    _test_measure("SFD_Multizone_2story_SL_UA_GRG_2Bed_2Bath_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_living_spaces+num_bedroom_spaces)
  end
  
  def test_mf_multi_zone
    num_units = 2
    num_living_spaces = num_units*4
    num_bedroom_spaces = num_units*2
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"PeopleDefinition"=>num_living_spaces+num_bedroom_spaces, "People"=>num_living_spaces+num_bedroom_spaces, "ScheduleRuleset"=>2}
    expected_values = {"NumOccupants"=>2.47*num_units, "SpaceType"=>2}
    _test_measure("MF_2units_Multizone_2story_SL_UA_GRG_2Bed_2Bath_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_living_spaces+num_bedroom_spaces)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = AddResidentialOccupants.new
    
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
    measure = AddResidentialOccupants.new

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
    
    actual_values = {"NumOccupants"=>0, "SpaceType"=>[]}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "People"
                actual_values["NumOccupants"] += new_object.peopleDefinition.numberofPeople.get
                actual_values["SpaceType"] << new_object.space.get.spaceType.get.standardsSpaceType.get
            end
        end
    end
    assert_in_epsilon(expected_values["NumOccupants"], actual_values["NumOccupants"], 0.01)
    if not expected_values["SpaceType"].nil?
        assert_equal(expected_values["SpaceType"], actual_values["SpaceType"].uniq.size)
    end

    return model
  end
  
end

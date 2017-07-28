# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'json'

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ResidentialGeometryFromEditor < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Residential Geometry from Editor"
  end

  # human readable description
  def description
    return "Imports a floorplan JSON file written by the OpenStudio Geometry Editor."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Currently this measure deletes the existing geometry and replaces it. In the future, a more advanced merge technique will be employed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # path to the floorplan JSON file to load
    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument("floorplan_path", true)
    arg.setDisplayName("Floorplan Path")
    arg.setDescription("Path to the floorplan JSON.")
    arg.setDefaultValue(File.join(File.dirname(__FILE__), "tests", "floorplan.json"))
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    floorplan_path = runner.getStringArgumentValue("floorplan_path", user_arguments)

    # check the floorplan_path for reasonableness
    if floorplan_path.empty?
      runner.registerError("Empty floorplan path was entered.")
      return false
    end
    
    path = runner.workflow.findFile(floorplan_path)
    if path.empty?
      runner.registerError("Cannot find floorplan path '#{floorplan_path}'.")
      return false
    end
    
    json = nil
    File.open(path.get.to_s, 'r') do |file|
      json = file.read
    end

    floorplan = OpenStudio::FloorplanJS::load(json)
    if floorplan.empty?
      runner.registerError("Cannot load floorplan from '#{floorplan_path}'.")
      return false
    end

    scene = floorplan.get.toThreeScene(true)
    
    new_model = OpenStudio::Model::modelFromThreeJS(scene)
    
    if new_model.empty?
      runner.registerError("Cannot convert floorplan to model.")
      return false
    end

    runner.registerInitialCondition("Initial model has #{model.getPlanarSurfaceGroups.size} planar surface groups")
    
    # mega lame merge
    model.getPlanarSurfaceGroups.each do |g|
      g.remove
    end
    
    new_model.get.getPlanarSurfaceGroups.each do |g| 
      g.clone(model)
    end
    
    runner.registerFinalCondition("Final model has #{model.getPlanarSurfaceGroups.size} planar surface groups")

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)
    
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)
    
    json = JSON.parse(json)

    # set the space type standards fields based on what user wrote in the editor
    json["space_types"].each do |st|
      model.getSpaceTypes.each do |space_type|
        next unless st["id"] == space_type.name.to_s
        space_type.setStandardsSpaceType(st["name"])
      end
    end
    
    # permit only expected space type names
    model.getSpaceTypes.each do |space_type|
      next if [Constants.AtticSpaceType, Constants.BasementSpaceType, Constants.CorridorSpaceType, Constants.CrawlSpaceType, Constants.GarageSpaceType, Constants.LivingSpaceType, Constants.PierBeamSpaceType].include? space_type.standardsSpaceType.get
      runner.registerError("Unexpected space type name '#{space_type.standardsSpaceType.get}'.")
      return false
    end

    # create and set thermal zones based on what the user wrote in the editor
    json["thermal_zones"].each do |tz|
      thermal_zone = OpenStudio::Model::ThermalZone.new(model)
      thermal_zone.setName(tz["name"])
      model.getSpaces.each do |space|
        json["stories"].each do |stories|
          stories["spaces"].each do |s|
            next unless s["name"] == space.name.to_s
            next unless s["thermal_zone_id"] == tz["id"]
            space.setThermalZone(thermal_zone)
          end
        end
      end
    end

    # for any spaces with no assigned zone, create (unless another space of the same space type has an assigned zone) a thermal zone based on the space type
    model.getSpaceTypes.each do |space_type|
      thermal_zone = nil
      space_type.spaces.each do |space|
        if thermal_zone.nil?
          if not space.thermalZone.is_initialized            
            thermal_zone = OpenStudio::Model::ThermalZone.new(model)
            thermal_zone.setName(space_type.standardsSpaceType.get)
          else
            thermal_zone = space.thermalZone.get
          end
        end
      end
      space_type.spaces.each do |space|
        unless space.thermalZone.is_initialized
          space.setThermalZone(thermal_zone)
        end
      end
    end
    
    # ensure that all spaces in a zone are either all finished or all unfinished
    model.getThermalZones.each do |thermal_zone|
      if thermal_zone.spaces.length == 0
        thermal_zone.remove
        next
      end
      unless thermal_zone.spaces.map {|space| Geometry.space_is_finished(space)}.uniq.size == 1
        runner.registerError("'#{thermal_zone.name}' has a mix of finished and unfinished spaces.")
        return false
      end
    end

    # set the building unit on spaces based on what the user wrote in the editor
    json["building_units"].each do |bu|
      building_unit = OpenStudio::Model::BuildingUnit.new(model)
      building_unit.setName(bu["name"])
      building_unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, 0.5) # FIXME
      model.getSpaces.each do |space|
        json["stories"].each do |stories|
          stories["spaces"].each do |s|
            next unless s["name"] == space.name.to_s
            next unless s["building_unit_id"] == bu["id"]
            space.setBuildingUnit(building_unit)
          end
        end
      end    
    end

    # set some required meta information
    if model.getBuildingUnits.length == 1
      model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeSingleFamilyDetached)
    else # TODO: how to determine SFA vs MF?
      model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeMultifamily)
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(Geometry.get_building_stories(model.getSpaces)) # FIXME: how to count finished attics as well?
    
    return true

  end
  
end

# register the measure to be used by the application
ResidentialGeometryFromEditor.new.registerWithApplication

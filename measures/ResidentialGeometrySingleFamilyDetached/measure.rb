# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialSingleFamilyDetachedGeometry < OpenStudio::Measure::ModelMeasure
    
  # human readable name
  def name
    return "Create Residential Single-Family Detached Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the building. Building is limited to one foundation type. Garage is tucked within the building, on the front left or front right corners of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Gathers living space area, wall height per floor, number of floors, aspect ratio, garage width and depth, garage position, foundation type and wall height, attic and roof type, and roof pitch. Constructs building by calculating footprint and performing a series of affine transformations into living, foundation, and attic spaces."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for total living space floor area
    total_ffa = OpenStudio::Measure::OSArgument::makeDoubleArgument("total_ffa",true)
    total_ffa.setDisplayName("Total Finished Floor Area")
    total_ffa.setUnits("ft^2")
    total_ffa.setDescription("The total floor area of the finished space (including any finished basement floor area).")
    total_ffa.setDefaultValue(2000.0)
    args << total_ffa
	
    #make an argument for living space height
    living_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("living_height",true)
    living_height.setDisplayName("Wall Height (Per Floor)")
    living_height.setUnits("ft")
    living_height.setDescription("The height of the living space (and garage) walls.")
    living_height.setDefaultValue(8.0)
    args << living_height	
	
    #make an argument for number of floors
    num_floors = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Num Floors")
    num_floors.setUnits("#")
    num_floors.setDescription("The number of floors above grade.")
    num_floors.setDefaultValue(2)
    args << num_floors
	
    #make an argument for aspect ratio
    aspect_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("aspect_ratio",true)
    aspect_ratio.setDisplayName("Aspect Ratio")
    aspect_ratio.setUnits("FB/LR")
    aspect_ratio.setDescription("The ratio of the front/back wall length to the left/right wall length, excluding any protruding garage wall area.")
    aspect_ratio.setDefaultValue(2.0)
    args << aspect_ratio
	
    #make a double argument for garage area
    garage_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_width", true)
    garage_width.setDisplayName("Garage Width")
    garage_width.setUnits("ft")
    garage_width.setDescription("The width of the garage.")
    garage_width.setDefaultValue(0.0)
    args << garage_width
	
    #make a double argument for garage height
    garage_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_depth", true)
    garage_depth.setDisplayName("Garage Depth")
    garage_depth.setUnits("ft")
    garage_depth.setDescription("The depth of the garage.")
    garage_depth.setDefaultValue(20.0)
    args << garage_depth

    #make a double argument for garage protrusion
    garage_protrusion = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_protrusion", true)
    garage_protrusion.setDisplayName("Garage Protrusion")
    garage_protrusion.setUnits("frac")
    garage_protrusion.setDescription("The fraction of the garage that is protruding from the living space.")
    garage_protrusion.setDefaultValue(0.0)
    args << garage_protrusion
    
    #make a choice argument for model objects
    garage_pos_display_names = OpenStudio::StringVector.new
    garage_pos_display_names << "Right"
    garage_pos_display_names << "Left"
	
    #make a choice argument for garage position
    garage_pos = OpenStudio::Measure::OSArgument::makeChoiceArgument("garage_pos", garage_pos_display_names, true)
    garage_pos.setDisplayName("Garage Position")
    garage_pos.setDescription("The position of the garage.")
    garage_pos.setDefaultValue("Right")
    args << garage_pos		
	
    #make a choice argument for model objects
    foundation_display_names = OpenStudio::StringVector.new
    foundation_display_names << Constants.SlabFoundationType
    foundation_display_names << Constants.CrawlFoundationType
    foundation_display_names << Constants.UnfinishedBasementFoundationType
    foundation_display_names << Constants.FinishedBasementFoundationType
    foundation_display_names << Constants.PierBeamFoundationType
	
    #make a choice argument for foundation type
    foundation_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("foundation_type", foundation_display_names, true)
    foundation_type.setDisplayName("Foundation Type")
    foundation_type.setDescription("The foundation type of the building.")
    foundation_type.setDefaultValue(Constants.SlabFoundationType)
    args << foundation_type

    #make an argument for crawlspace height
    foundation_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_height",true)
    foundation_height.setDisplayName("Crawlspace Height")
    foundation_height.setUnits("ft")
    foundation_height.setDescription("The height of the crawlspace walls.")
    foundation_height.setDefaultValue(3.0)
    args << foundation_height
	
    #make a choice argument for model objects
    attic_type_display_names = OpenStudio::StringVector.new
    attic_type_display_names << Constants.UnfinishedAtticType
    attic_type_display_names << Constants.FinishedAtticType
	
    #make a choice argument for attic type
    attic_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("attic_type", attic_type_display_names, true)
    attic_type.setDisplayName("Attic Type")
    attic_type.setDescription("The attic type of the building.")
    attic_type.setDefaultValue(Constants.UnfinishedAtticType)
    args << attic_type	
	
    #make a choice argument for model objects
    roof_type_display_names = OpenStudio::StringVector.new
    roof_type_display_names << Constants.RoofTypeGable
    roof_type_display_names << Constants.RoofTypeHip
    roof_type_display_names << Constants.RoofTypeFlat
	
    #make a choice argument for roof type
    roof_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_type", roof_type_display_names, true)
    roof_type.setDisplayName("Roof Type")
    roof_type.setDescription("The roof type of the building.")
    roof_type.setDefaultValue(Constants.RoofTypeGable)
    args << roof_type
	
    #make a choice argument for model objects
    roof_pitch_display_names = OpenStudio::StringVector.new
    roof_pitch_display_names << "1:12"
    roof_pitch_display_names << "2:12"
    roof_pitch_display_names << "3:12"
    roof_pitch_display_names << "4:12"
    roof_pitch_display_names << "5:12"
    roof_pitch_display_names << "6:12"
    roof_pitch_display_names << "7:12"
    roof_pitch_display_names << "8:12"
    roof_pitch_display_names << "9:12"
    roof_pitch_display_names << "10:12"
    roof_pitch_display_names << "11:12"
    roof_pitch_display_names << "12:12"
	
    #make a choice argument for roof pitch
    roof_pitch = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_pitch", roof_pitch_display_names, true)
    roof_pitch.setDisplayName("Roof Pitch")
    roof_pitch.setDescription("The roof pitch of the attic.")
    roof_pitch.setDefaultValue("6:12")
    args << roof_pitch
		
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    total_ffa = runner.getDoubleArgumentValue("total_ffa",user_arguments)
    living_height = runner.getDoubleArgumentValue("living_height",user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    aspect_ratio = runner.getDoubleArgumentValue("aspect_ratio",user_arguments)
    garage_width = runner.getDoubleArgumentValue("garage_width",user_arguments)
    garage_depth = runner.getDoubleArgumentValue("garage_depth",user_arguments)
    garage_protrusion = runner.getDoubleArgumentValue("garage_protrusion",user_arguments)
    garage_pos = runner.getStringArgumentValue("garage_pos",user_arguments)
    foundation_type = runner.getStringArgumentValue("foundation_type",user_arguments)
    foundation_height = runner.getDoubleArgumentValue("foundation_height",user_arguments)
    attic_type = runner.getStringArgumentValue("attic_type",user_arguments)
    roof_type = runner.getStringArgumentValue("roof_type",user_arguments)
    roof_pitch = {"1:12"=>1.0/12.0, "2:12"=>2.0/12.0, "3:12"=>3.0/12.0, "4:12"=>4.0/12.0, "5:12"=>5.0/12.0, "6:12"=>6.0/12.0, "7:12"=>7.0/12.0, "8:12"=>8.0/12.0, "9:12"=>9.0/12.0, "10:12"=>10.0/12.0, "11:12"=>11.0/12.0, "12:12"=>12.0/12.0}[runner.getStringArgumentValue("roof_pitch",user_arguments)]
    
    if foundation_type == Constants.SlabFoundationType
      foundation_height = 0.0
    elsif foundation_type == Constants.UnfinishedBasementFoundationType or foundation_type == Constants.FinishedBasementFoundationType
      foundation_height = 8.0
    end
    
    # error checking
    if model.getSpaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    if foundation_type == Constants.CrawlFoundationType and ( foundation_height < 1.5 or foundation_height > 5.0 )
      runner.registerError("The crawlspace height can be set between 1.5 and 5 ft.")
      return false
    end
    if foundation_type == Constants.PierBeamFoundationType and ( foundation_height <= 0.0 )
      runner.registerError("The pier & beam height must be greater than 0 ft.")
      return false
    end
    if num_floors > 6
      runner.registerError("Too many floors.")
      return false
    end
    if garage_protrusion < 0 or garage_protrusion > 1
      runner.registerError("Invalid garage protrusion value entered.")
      return false
    end
    
    # Convert to SI
    total_ffa = OpenStudio.convert(total_ffa,"ft^2","m^2").get
    living_height = OpenStudio.convert(living_height,"ft","m").get
    garage_width = OpenStudio::convert(garage_width,"ft","m").get
    garage_depth = OpenStudio::convert(garage_depth,"ft","m").get
    foundation_height = OpenStudio.convert(foundation_height,"ft","m").get
    
    garage_area = garage_width * garage_depth
    has_garage = false
    if garage_area > 0
      has_garage = true
    end
    
    # error checking
    if garage_protrusion > 0 and roof_type == Constants.RoofTypeHip and has_garage
      runner.registerError("Cannot handle protruding garage and hip roof.")
      return false
    end
    if garage_protrusion > 0 and aspect_ratio < 1 and has_garage and roof_type == Constants.RoofTypeGable
      runner.registerError("Cannot handle protruding garage and attic ridge running from front to back.")
      return false
    end
    if foundation_type == Constants.PierBeamFoundationType and has_garage
      runner.registerError("Cannot handle garages with a pier & beam foundation type.")
      return false
    end    
    
    # calculate the footprint of the building
    garage_area_inside_footprint = 0
    if has_garage
      garage_area_inside_footprint = garage_area * (1.0 - garage_protrusion)      
    end
    bonus_area_above_garage = garage_area * garage_protrusion
    if foundation_type == Constants.FinishedBasementFoundationType and attic_type == Constants.FinishedAtticType
      footprint = (total_ffa + 2 * garage_area_inside_footprint - (num_floors) * bonus_area_above_garage) / (num_floors + 2)
    elsif foundation_type == Constants.FinishedBasementFoundationType
      footprint = (total_ffa + 2 * garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / (num_floors + 1)
    elsif attic_type == Constants.FinishedAtticType
      footprint = (total_ffa + garage_area_inside_footprint - (num_floors) * bonus_area_above_garage) / (num_floors + 1)
    else
      footprint = (total_ffa + garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / num_floors
    end
	
    # calculate the dimensions of the building
    width = Math.sqrt(footprint / aspect_ratio)
    length = footprint / width
	
    # error checking
    if (garage_width > length and garage_depth > 0) or (((1.0 - garage_protrusion) * garage_depth) > width and garage_width > 0) or (((1.0 - garage_protrusion) * garage_depth) == width and garage_width == length)
      runner.registerError("Invalid living space and garage dimensions.")
      return false
    end    
	
    # starting spaces
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")
	
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    # living_zone.setName(Constants.LivingZone)
	
    foundation_offset = 0.0
    if foundation_type == Constants.PierBeamFoundationType
      foundation_offset = foundation_height
    end

    space_types_hash = {}
    
    # loop through the number of floors
    foundation_polygon_with_wrong_zs = nil
    for floor in (0..num_floors-1)
	
      z = living_height * floor + foundation_offset
		
      if has_garage and z == foundation_offset # first floor and has garage
        
        # create garage zone
        garage_zone = OpenStudio::Model::ThermalZone.new(model)
        # garage_zone.setName(Constants.GarageZone)
        
        # make points and polygons
        if garage_pos == "Right"
          garage_sw_point = OpenStudio::Point3d.new(length-garage_width,-garage_protrusion*garage_depth,z)
          garage_nw_point = OpenStudio::Point3d.new(length-garage_width,garage_depth-garage_protrusion*garage_depth,z)
          garage_ne_point = OpenStudio::Point3d.new(length,garage_depth-garage_protrusion*garage_depth,z)
          garage_se_point = OpenStudio::Point3d.new(length,-garage_protrusion*garage_depth,z)
          garage_polygon = Geometry.make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)		
        elsif garage_pos == "Left"
          garage_sw_point = OpenStudio::Point3d.new(0,-garage_protrusion*garage_depth,z)
          garage_nw_point = OpenStudio::Point3d.new(0,garage_depth-garage_protrusion*garage_depth,z)
          garage_ne_point = OpenStudio::Point3d.new(garage_width,garage_depth-garage_protrusion*garage_depth,z)
          garage_se_point = OpenStudio::Point3d.new(garage_width,-garage_protrusion*garage_depth,z)
          garage_polygon = Geometry.make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)			
        end
        
        # make space
        garage_space = OpenStudio::Model::Space::fromFloorPrint(garage_polygon, living_height, model)
        garage_space = garage_space.get
        garage_space_name = Constants.GarageSpace
        # garage_space.setName(garage_space_name)
        if space_types_hash.keys.include? Constants.GarageSpaceType
          garage_space_type = space_types_hash[Constants.GarageSpaceType]
        else
          garage_space_type = OpenStudio::Model::SpaceType.new(model)
          garage_space_type.setStandardsSpaceType(Constants.GarageSpaceType)
          space_types_hash[Constants.GarageSpaceType] = garage_space_type
        end
        garage_space.setSpaceType(garage_space_type)
        runner.registerInfo("Set #{garage_space_name}.")
          
        # set this to the garage zone
        garage_space.setThermalZone(garage_zone)
        
        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[0,3] = 0
        m[1,3] = 0
        m[2,3] = z
        garage_space.changeTransformation(OpenStudio::Transformation.new(m))

        if garage_pos == "Right"
          sw_point = OpenStudio::Point3d.new(0,0,z)
          nw_point = OpenStudio::Point3d.new(0,width,z)
          ne_point = OpenStudio::Point3d.new(length,width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          l_se_point = OpenStudio::Point3d.new(length-garage_width,0,z)
          if ( garage_depth < width or garage_protrusion > 0 ) and garage_protrusion < 1 # garage protrudes but not fully
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, garage_ne_point, garage_nw_point, l_se_point)
          elsif garage_protrusion < 1 # garage fits perfectly within living space
            living_polygon = Geometry.make_polygon(sw_point, nw_point, garage_nw_point, garage_sw_point)
          else # garage fully protrudes
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)          
          end
        elsif garage_pos == "Left"
          sw_point = OpenStudio::Point3d.new(0,0,z)
          nw_point = OpenStudio::Point3d.new(0,width,z)
          ne_point = OpenStudio::Point3d.new(length,width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          l_sw_point = OpenStudio::Point3d.new(garage_width,0,z)
          if ( garage_depth < width or garage_protrusion > 0 ) and garage_protrusion < 1 # garage protrudes but not fully
            living_polygon = Geometry.make_polygon(garage_nw_point, nw_point, ne_point, se_point, l_sw_point, garage_ne_point)
          elsif garage_protrusion < 1 # garage fits perfectly within living space
            living_polygon = Geometry.make_polygon(garage_se_point, garage_ne_point, ne_point, se_point)
          else # garage fully protrudes
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)          
          end
        end
        foundation_polygon_with_wrong_zs = living_polygon			
      
      else # first floor without garage or above first floor
        
        if has_garage
          garage_se_point = OpenStudio::Point3d.new(garage_se_point.x, garage_se_point.y, living_height * floor + foundation_offset)
          garage_sw_point = OpenStudio::Point3d.new(garage_sw_point.x, garage_sw_point.y, living_height * floor + foundation_offset)
          garage_nw_point = OpenStudio::Point3d.new(garage_nw_point.x, garage_nw_point.y, living_height * floor + foundation_offset)
          garage_ne_point = OpenStudio::Point3d.new(garage_ne_point.x, garage_ne_point.y, living_height * floor + foundation_offset)          
          if garage_pos == "Right"
            sw_point = OpenStudio::Point3d.new(0,0,z)
            nw_point = OpenStudio::Point3d.new(0,width,z)
            ne_point = OpenStudio::Point3d.new(length,width,z)
            se_point = OpenStudio::Point3d.new(length,0,z)
            l_se_point = OpenStudio::Point3d.new(length-garage_width,0,z)
            if garage_protrusion > 0 # garage protrudes
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, garage_se_point, garage_sw_point, l_se_point)
            else # garage does not protrude
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)     
            end
          elsif garage_pos == "Left"
            sw_point = OpenStudio::Point3d.new(0,0,z)
            nw_point = OpenStudio::Point3d.new(0,width,z)
            ne_point = OpenStudio::Point3d.new(length,width,z)
            se_point = OpenStudio::Point3d.new(length,0,z)
            l_sw_point = OpenStudio::Point3d.new(garage_width,0,z)
            if garage_protrusion > 0 # garage protrudes
              living_polygon = Geometry.make_polygon(garage_sw_point, nw_point, ne_point, se_point, l_sw_point, garage_se_point)            
            else # garage does not protrude
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)          
            end
          end
        
        else
      
          sw_point = OpenStudio::Point3d.new(0,0,z)	
          nw_point = OpenStudio::Point3d.new(0,width,z)
          ne_point = OpenStudio::Point3d.new(length,width,z)
          se_point = OpenStudio::Point3d.new(length,0,z)
          living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
          if z == foundation_offset
            foundation_polygon_with_wrong_zs = living_polygon
          end
          
        end
        
      end

      # make space
      living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
      living_space = living_space.get   
      living_space_name = Constants.LivingSpace(floor+1)
      # living_space.setName(living_space_name)
      if space_types_hash.keys.include? Constants.LivingSpaceType
        living_space_type = space_types_hash[Constants.LivingSpaceType]
      else
        living_space_type = OpenStudio::Model::SpaceType.new(model)
        living_space_type.setStandardsSpaceType(Constants.LivingSpaceType)
        space_types_hash[Constants.LivingSpaceType] = living_space_type
      end
      living_space.setSpaceType(living_space_type)
      runner.registerInfo("Set #{living_space_name}.")
      
      # set these to the living zone
      living_space.setThermalZone(living_zone)
      
      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
      m[0,3] = 0
      m[1,3] = 0
      m[2,3] = z
      living_space.changeTransformation(OpenStudio::Transformation.new(m))
		
    end
	
    # Attic
    if roof_type != Constants.RoofTypeFlat
    
      z = z + living_height
      
      # calculate the dimensions of the attic
      if length >= width
        attic_height = (width / 2.0) * roof_pitch
      else
        attic_height = (length / 2.0) * roof_pitch
      end

      # make points
      roof_nw_point = OpenStudio::Point3d.new(0,width,z)
      roof_ne_point = OpenStudio::Point3d.new(length,width,z)
      roof_se_point = OpenStudio::Point3d.new(length,0,z)
      roof_sw_point = OpenStudio::Point3d.new(0,0,z)	
      
      # make polygons
      polygon_floor = Geometry.make_polygon(roof_nw_point, roof_ne_point, roof_se_point, roof_sw_point)	
      side_type = nil
      if roof_type == Constants.RoofTypeGable
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(0,width/2.0,z+attic_height)
          roof_e_point = OpenStudio::Point3d.new(length,width/2.0,z+attic_height)			
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_se_point, roof_ne_point)		
        else
          roof_w_point = OpenStudio::Point3d.new(length/2.0,0,z+attic_height)
          roof_e_point = OpenStudio::Point3d.new(length/2.0,width,z+attic_height)		
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = "Wall"
      elsif roof_type == Constants.RoofTypeHip
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(width/2.0,width/2.0,z+attic_height)
          roof_e_point = OpenStudio::Point3d.new(length-width/2.0,width/2.0,z+attic_height)			
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_se_point, roof_ne_point)		
        else
          roof_w_point = OpenStudio::Point3d.new(length/2.0,length/2.0,z+attic_height)
          roof_e_point = OpenStudio::Point3d.new(length/2.0,width-length/2.0,z+attic_height)
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_ne_point, roof_nw_point)	
        end
        side_type = "RoofCeiling"
      end
      
      # make surfaces
      surface_floor = OpenStudio::Model::Surface.new(polygon_floor, model)
      surface_floor.setSurfaceType("Floor") 
      surface_floor.setOutsideBoundaryCondition("Surface") 
      surface_s_roof = OpenStudio::Model::Surface.new(polygon_s_roof, model)
      surface_s_roof.setSurfaceType("RoofCeiling") 
      surface_s_roof.setOutsideBoundaryCondition("Outdoors")	
      surface_n_roof = OpenStudio::Model::Surface.new(polygon_n_roof, model)
      surface_n_roof.setSurfaceType("RoofCeiling") 
      surface_n_roof.setOutsideBoundaryCondition("Outdoors")		
      surface_w_wall = OpenStudio::Model::Surface.new(polygon_w_wall, model)
      surface_w_wall.setSurfaceType(side_type) 
      surface_w_wall.setOutsideBoundaryCondition("Outdoors")
      surface_e_wall = OpenStudio::Model::Surface.new(polygon_e_wall, model)
      surface_e_wall.setSurfaceType(side_type) 
      surface_e_wall.setOutsideBoundaryCondition("Outdoors")
      
      # assign surfaces to the space
      attic_space = OpenStudio::Model::Space.new(model)
      surface_floor.setSpace(attic_space)
      surface_s_roof.setSpace(attic_space)
      surface_n_roof.setSpace(attic_space)
      surface_w_wall.setSpace(attic_space)
      surface_e_wall.setSpace(attic_space)
      
      # set these to the attic zone
      if attic_type == Constants.UnfinishedAtticType        
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        # attic_zone.setName(Constants.UnfinishedAtticZone)
        attic_space.setThermalZone(attic_zone)
        attic_space_name = Constants.UnfinishedAtticSpace
        attic_space_type_name = Constants.AtticSpaceType
      elsif attic_type == Constants.FinishedAtticType
        attic_space.setThermalZone(living_zone)
        attic_space_name = Constants.FinishedAtticSpace
        attic_space_type_name = Constants.LivingSpaceType
      end

      # attic_space.setName(attic_space_name)
      if space_types_hash.keys.include? attic_space_type_name
        attic_space_type = space_types_hash[attic_space_type_name]
      else
        attic_space_type = OpenStudio::Model::SpaceType.new(model)
        attic_space_type.setStandardsSpaceType(attic_space_type_name)
        space_types_hash[attic_space_type_name] = attic_space_type
      end
      attic_space.setSpaceType(attic_space_type)
      runner.registerInfo("Set #{attic_space_name}.")
      
      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
      m[0,3] = 0
      m[1,3] = 0
      m[2,3] = z
      attic_space.changeTransformation(OpenStudio::Transformation.new(m))	
      
    end
	
    # Foundation
    if [Constants.CrawlFoundationType, Constants.UnfinishedBasementFoundationType, Constants.FinishedBasementFoundationType, Constants.PierBeamFoundationType].include? foundation_type
      
      z = -foundation_height + foundation_offset		
      
      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)
      if foundation_type == Constants.CrawlFoundationType
        foundation_zone_name = Constants.CrawlZone
      elsif foundation_type == Constants.UnfinishedBasementFoundationType
        foundation_zone_name = Constants.UnfinishedBasementZone
      elsif foundation_type == Constants.FinishedBasementFoundationType
        foundation_zone_name = Constants.FinishedBasementZone
      elsif foundation_type == Constants.PierBeamFoundationType
        foundation_zone_name = Constants.PierBeamZone
      end
      # foundation_zone.setName(foundation_zone_name)

      # make polygons
      p = OpenStudio::Point3dVector.new
      foundation_polygon_with_wrong_zs.each do |point|
        p << OpenStudio::Point3d.new(point.x,point.y,z)
      end
      foundation_polygon = p
      
      # make space
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      if foundation_type == Constants.CrawlFoundationType
        foundation_space_name = Constants.CrawlSpace
        foundation_space_type_name = Constants.CrawlSpaceType
      elsif foundation_type == Constants.UnfinishedBasementFoundationType
        foundation_space_name = Constants.UnfinishedBasementSpace
        foundation_space_type_name = Constants.BasementSpaceType
      elsif foundation_type == Constants.FinishedBasementFoundationType
        foundation_space_name = Constants.FinishedBasementSpace
        foundation_space_type_name = Constants.LivingSpaceType
      elsif foundation_type == Constants.PierBeamFoundationType
        foundation_space_name = Constants.PierBeamSpace
        foundation_space_type_name = Constants.PierBeamSpaceType
      end
      # foundation_space.setName(foundation_space_name)
      if space_types_hash.keys.include? foundation_space_type_name
        foundation_space_type = space_types_hash[foundation_space_type_name]
      else
        foundation_space_type = OpenStudio::Model::SpaceType.new(model)
        foundation_space_type.setStandardsSpaceType(foundation_space_type_name)
        space_types_hash[foundation_space_type_name] = foundation_space_type
      end
      foundation_space.setSpaceType(foundation_space_type)      
      runner.registerInfo("Set #{foundation_space_name}.")

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)	
      
      # set foundation walls outside boundary condition
      spaces = model.getSpaces
      spaces.each do |space|
        if Geometry.get_space_floor_z(space) < 0
          surfaces = space.surfaces
          surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.setOutsideBoundaryCondition("Ground")
          end
        end
      end

      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
      m[0,3] = 0
      m[1,3] = 0
      m[2,3] = z
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))	
    
    end
    
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if has_garage and roof_type != Constants.RoofTypeFlat
      if num_floors > 1
        space_with_roof_over_garage = living_space
      else
        space_with_roof_over_garage = garage_space
      end
      space_with_roof_over_garage.surfaces.each do |surface|
        if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
          n_points = []
          s_points = []
          surface.vertices.each do |vertex|
            if vertex.y == 0
              n_points << vertex
            elsif vertex.y < 0
              s_points << vertex
            end
          end
          if n_points[0].x > n_points[1].x
            nw_point = n_points[1]
            ne_point = n_points[0]
          else
            nw_point = n_points[0]
            ne_point = n_points[1]
          end
          if s_points[0].x > s_points[1].x
            sw_point = s_points[1]
            se_point = s_points[0]
          else
            sw_point = s_points[0]
            se_point = s_points[1]
          end
          
          if num_floors == 1
            if not attic_type == Constants.FinishedAtticType
              nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, living_space.zOrigin+nw_point.z)
              ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, living_space.zOrigin+ne_point.z)
              sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, living_space.zOrigin+sw_point.z)
              se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, living_space.zOrigin+se_point.z)
            else
              nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, nw_point.z-living_space.zOrigin)
              ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, ne_point.z-living_space.zOrigin)
              sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, sw_point.z-living_space.zOrigin)
              se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, se_point.z-living_space.zOrigin)
            end
          else
            nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, num_floors*nw_point.z)
            ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, num_floors*ne_point.z)
            sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, num_floors*sw_point.z)
            se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, num_floors*se_point.z)
          end
          
          garage_attic_height = (ne_point.x - nw_point.x)/2 * roof_pitch          
          
          garage_roof_pitch = roof_pitch
          if garage_attic_height >= attic_height
            garage_attic_height = attic_height - 0.01 # garage attic height slightly below attic height so that we don't get any roof decks with only three vertices
            garage_roof_pitch = garage_attic_height / ( garage_width / 2 )
            runner.registerWarning("The garage pitch was changed to accommodate garage ridge >= house ridge (from #{roof_pitch.round(3)} to #{garage_roof_pitch.round(3)}).")
          end

          if num_floors == 1
            if not attic_type == Constants.FinishedAtticType
              roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x)/2, nw_point.y+garage_attic_height/roof_pitch, living_space.zOrigin+living_height+garage_attic_height)
              roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x)/2, sw_point.y, living_space.zOrigin+living_height+garage_attic_height)
            else
              roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x)/2, nw_point.y+garage_attic_height/roof_pitch, garage_attic_height+living_height)
              roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x)/2, sw_point.y, garage_attic_height+living_height)
            end
          else
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x)/2, nw_point.y+garage_attic_height/roof_pitch, num_floors*living_height+garage_attic_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x)/2, sw_point.y, num_floors*living_height+garage_attic_height) 
          end
          
          polygon_w_roof = Geometry.make_polygon(nw_point, sw_point, roof_s_point, roof_n_point)
          polygon_e_roof = Geometry.make_polygon(ne_point, roof_n_point, roof_s_point, se_point)
          polygon_n_wall = Geometry.make_polygon(nw_point, roof_n_point, ne_point)
          polygon_s_wall = Geometry.make_polygon(sw_point, se_point, roof_s_point)

          deck_w = OpenStudio::Model::Surface.new(polygon_w_roof, model)
          deck_w.setSurfaceType("RoofCeiling") 
          deck_w.setOutsideBoundaryCondition("Outdoors")           
          deck_e = OpenStudio::Model::Surface.new(polygon_e_roof, model)
          deck_e.setSurfaceType("RoofCeiling") 
          deck_e.setOutsideBoundaryCondition("Outdoors")
          wall_n = OpenStudio::Model::Surface.new(polygon_n_wall, model)
          wall_n.setSurfaceType("Wall")
          wall_s = OpenStudio::Model::Surface.new(polygon_s_wall, model)
          wall_s.setSurfaceType("Wall") 
          wall_s.setOutsideBoundaryCondition("Outdoors")

          garage_attic_space = OpenStudio::Model::Space.new(model)
          deck_w.setSpace(garage_attic_space)
          deck_e.setSpace(garage_attic_space)
          wall_n.setSpace(garage_attic_space)
          wall_s.setSpace(garage_attic_space)
          
          if attic_type == Constants.FinishedAtticType
          
            garage_attic_space_name = Constants.GarageFinishedAtticSpace
            garage_attic_space.setThermalZone(living_zone)
            garage_attic_space_type_name = Constants.LivingSpaceType
            
          else
          
            garage_attic_space_name = Constants.GarageAtticSpace
            garage_attic_space.setThermalZone(attic_zone)
            garage_attic_space_type_name = Constants.AtticSpaceType
            
          end
          
          surface.createAdjacentSurface(garage_attic_space)
          # garage_attic_space.setName(garage_attic_space_name)
          if space_types_hash.keys.include? garage_attic_space_type_name
            garage_attic_space_type = space_types_hash[garage_attic_space_type_name]
          else
            garage_attic_space_type = OpenStudio::Model::SpaceType.new(model)
            garage_attic_space_type.setStandardsSpaceType(garage_attic_space_type_name)
            space_types_hash[garage_attic_space_type_name] = garage_attic_space_type
          end
          garage_attic_space.setSpaceType(garage_attic_space_type)
          runner.registerInfo("Set #{garage_attic_space_name}.")
          
          break
          
        end
      end      
    end
  
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)
    
    # remove triangular surface between unfinished attic and garage attic
    unless attic_space.nil?
      attic_space.surfaces.each do |surface|
        next if roof_type == Constants.RoofTypeHip
        next unless surface.vertices.length == 3
        next unless (90 - surface.tilt*180/Math::PI).abs > 0.01 # don't remove the vertical attic walls
        next unless surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.remove
        surface.remove
      end
    end
    
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)
  
    # Store number of stories
    if attic_type == Constants.FinishedAtticType
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    if foundation_type == Constants.FinishedBasementFoundationType
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)
    
    # Store the building type
    model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeSingleFamilyDetached)
  
    # Store info for HVAC Sizing measure
    if has_garage
      if num_floors > 1 # garage completely under living space
        unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, 1.0)
      elsif attic_type == Constants.FinishedAtticType # garage completely under finished attic
        unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, 1.0)
      else # 1-story w/o finished attic
        unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, garage_protrusion)
      end
    end
    
    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")
    
    return true

  end #end the run method
    
end #end the measure

# register the measure to be used by the application
CreateResidentialSingleFamilyDetachedGeometry.new.registerWithApplication

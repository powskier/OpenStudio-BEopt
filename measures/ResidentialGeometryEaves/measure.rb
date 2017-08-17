# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialEaves < OpenStudio::Measure::ModelMeasure
  
  # human readable name
  def name
    return "Set Residential Eaves"
  end

  # human readable description
  def description
    return "Sets the eaves for the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Performs a series of affine transformations on the roof decks into shading surfaces."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a choice argument for model objects
    roof_structure_display_names = OpenStudio::StringVector.new
    roof_structure_display_names << Constants.RoofStructureTrussCantilever
    roof_structure_display_names << Constants.RoofStructureRafter
    
    #make a choice argument for roof type
    roof_structure = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_structure", roof_structure_display_names, true)
    roof_structure.setDisplayName("Roof Structure")
    roof_structure.setDescription("The roof structure of the building.")
    roof_structure.setDefaultValue(Constants.RoofStructureTrussCantilever)
    args << roof_structure    
    
    #make a choice argument for eaves depth
    eaves_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("eaves_depth", true)
    eaves_depth.setDisplayName("Eaves Depth")
    eaves_depth.setUnits("ft")
    eaves_depth.setDescription("The eaves depth of the roof.")
    eaves_depth.setDefaultValue(2.0)
    args << eaves_depth 
  
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    roof_structure = runner.getStringArgumentValue("roof_structure",user_arguments)
    eaves_depth = OpenStudio.convert(runner.getDoubleArgumentValue("eaves_depth",user_arguments),"ft","m").get

    # remove existing eaves
    num_removed = 0
    existing_eaves_depth = nil
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      next unless shading_surface_group.name.to_s == Constants.ObjectNameEaves
      shading_surface_group.shadingSurfaces.each do |shading_surface|
        num_removed += 1
        next unless existing_eaves_depth.nil?
        existing_eaves_depth = get_existing_eaves_depth(shading_surface)
      end
      shading_surface_group.remove
      runner.registerInfo("Removed existing #{Constants.ObjectNameEaves}.")
    end
    if num_removed > 0
      runner.registerInfo("#{num_removed} eaves shading surfaces removed.")
    end
    
    # No eaves to add? Exit here.
    if eaves_depth == 0 and num_removed == 0
      runner.registerAsNotApplicable("No eaves were added or removed.")
      return true
    end    
    if existing_eaves_depth.nil?
      existing_eaves_depth = 0
    end
    
    surfaces_modified = false
    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    shading_surface_group.setName(Constants.ObjectNameEaves)

    model.getSurfaces.each do |roof_surface|

      next unless roof_surface.surfaceType.downcase == "roofceiling"
      next unless roof_surface.outsideBoundaryCondition.downcase == "outdoors"
      
      if roof_structure == Constants.RoofStructureTrussCantilever
      
        l, w, h = Geometry.get_surface_dimensions(roof_surface)
        if l < w
          lift = (h / l) * eaves_depth
        else
          lift = (h / w) * eaves_depth
        end

        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[2, 3] = lift
        transformation = OpenStudio::Transformation.new(m)
        new_vertices = transformation * roof_surface.vertices
        roof_surface.setVertices(new_vertices)
        
      end
      
      surfaces_modified = true
    
      if roof_surface.vertices.length > 3      
      
        vertex_dir_backup = roof_surface.vertices[-3]
        vertex_dir = roof_surface.vertices[-2]
        vertex_1 = roof_surface.vertices[-1]

        roof_surface.vertices[0..-1].each do |vertex|

          l, w, h = Geometry.get_surface_dimensions(roof_surface)
          if l < w
            tilt = Math.atan(h / l)
          else
            tilt = Math.atan(h / w)
          end

          z = eaves_depth / Math.cos(tilt)
          scale =  z / eaves_depth
        
          vertex_2 = vertex

          dir_vector = OpenStudio::Vector3d.new(vertex_1.x - vertex_dir.x, vertex_1.y - vertex_dir.y, vertex_1.z - vertex_dir.z) # works if angles are right angles
          
          if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
            dir_vector = OpenStudio::Vector3d.new(0, vertex_1.y - vertex_dir.y, vertex_1.z - vertex_dir.z)
          end          
          
          if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
            dir_vector = OpenStudio::Vector3d.new(vertex_1.x - vertex_dir.x, 0, vertex_1.z - vertex_dir.z)
          end
          
          if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
            dir_vector = OpenStudio::Vector3d.new(0, vertex_1.y - vertex_dir.y, vertex_1.z - vertex_dir.z)
          end
          
          if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
            dir_vector = OpenStudio::Vector3d.new(vertex_1.x - vertex_dir_backup.x, vertex_1.y - vertex_dir_backup.y, vertex_1.z - vertex_dir_backup.z)
          end          

          dir_vector_n = OpenStudio::Vector3d.new(dir_vector.x / dir_vector.length, dir_vector.y / dir_vector.length, dir_vector.z / dir_vector.length) # normalize
          
          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[0, 3] = dir_vector_n.x * eaves_depth * scale
          m[1, 3] = dir_vector_n.y * eaves_depth * scale
          m[2, 3] = dir_vector_n.z * eaves_depth * scale

          new_vertices = OpenStudio::Point3dVector.new
          new_vertices << OpenStudio::Transformation.new(m) * vertex_1
          new_vertices << OpenStudio::Transformation.new(m) * vertex_2
          new_vertices << vertex_2
          new_vertices << vertex_1
          
          vertex_dir_backup = vertex_dir
          vertex_dir = vertex_1
          vertex_1 = vertex_2

          next if dir_vector.length == 0
          next if dir_vector_n.z > 0          
          
          if OpenStudio::getOutwardNormal(new_vertices).get.z < 0
            transformation = OpenStudio::Transformation.rotation(new_vertices[2], OpenStudio::Vector3d.new(new_vertices[2].x - new_vertices[3].x, new_vertices[2].y - new_vertices[3].y, new_vertices[2].z - new_vertices[3].z), 3.14159)
            new_vertices = transformation * new_vertices
          end

          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[2, 3] = roof_surface.space.get.zOrigin
          new_vertices = OpenStudio::Transformation.new(m) * new_vertices
=begin
          shared_vertices = 0
          model.getSurfaces.each do |surface|
            next unless surface.surfaceType.downcase == "roofceiling"
            next unless surface.outsideBoundaryCondition.downcase == "outdoors"
            next if surface == roof_surface
            surface.vertices.each do |roof_vertex|
              new_vertices.each do |eave_vertex|
                next unless roof_vertex == eave_vertex
                shared_vertices += 1
              end
            end
          end          
          next if shared_vertices > 1
=end
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_vertices, model)
          shading_surface.setName("#{roof_surface.name} - #{Constants.ObjectNameEaves}")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)

        end

      elsif roof_surface.vertices.length == 3
        
        zmin = 9e99
        roof_surface.vertices.each do |vertex|
          zmin = [vertex.z, zmin].min
        end
        
        vertex_1 = nil
        vertex_2 = nil
        vertex_dir = nil
        roof_surface.vertices.each do |vertex|
          if vertex.z == zmin
            if vertex_1.nil?
              vertex_1 = vertex
            end
          end
          if vertex.z == zmin
            vertex_2 = vertex
          end
          if vertex.z != zmin
            vertex_dir = vertex
          end
        end

        l, w, h = Geometry.get_surface_dimensions(roof_surface)
        if l < w
          tilt = Math.atan(h / l)
        else
          tilt = Math.atan(h / w)
        end
        
        z = eaves_depth / Math.cos(tilt)
        scale =  z / eaves_depth
        
        dir_vector = OpenStudio::Vector3d.new(vertex_1.x - vertex_dir.x, vertex_1.y - vertex_dir.y, vertex_1.z - vertex_dir.z)
        
        if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
          dir_vector = OpenStudio::Vector3d.new(vertex_1.x - vertex_dir.x, 0, vertex_1.z - vertex_dir.z)
        end
        
        if not dir_vector.dot(OpenStudio::Vector3d.new(vertex_1.x - vertex_2.x, vertex_1.y - vertex_2.y, vertex_1.z - vertex_2.z)) == 0 # ensure perpendicular
          dir_vector = OpenStudio::Vector3d.new(0, vertex_1.y - vertex_dir.y, vertex_1.z - vertex_dir.z)
        end

        dir_vector_n = OpenStudio::Vector3d.new(dir_vector.x / dir_vector.length, dir_vector.y / dir_vector.length, dir_vector.z / dir_vector.length) # normalize
        
        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[0, 3] = dir_vector_n.x * eaves_depth * scale
        m[1, 3] = dir_vector_n.y * eaves_depth * scale
        m[2, 3] = dir_vector_n.z * eaves_depth * scale

        new_vertices = OpenStudio::Point3dVector.new
        new_vertices << OpenStudio::Transformation.new(m) * vertex_1
        new_vertices << OpenStudio::Transformation.new(m) * vertex_2
        new_vertices << vertex_2
        new_vertices << vertex_1

        next if dir_vector.length == 0
        next if dir_vector_n.z > 0          
        
        if OpenStudio::getOutwardNormal(new_vertices).get.z < 0
          transformation = OpenStudio::Transformation.rotation(new_vertices[2], OpenStudio::Vector3d.new(new_vertices[2].x - new_vertices[3].x, new_vertices[2].y - new_vertices[3].y, new_vertices[2].z - new_vertices[3].z), 3.14159)
          new_vertices = transformation * new_vertices
        end

        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[2, 3] = roof_surface.space.get.zOrigin
        new_vertices = OpenStudio::Transformation.new(m) * new_vertices
        
        shading_surface = OpenStudio::Model::ShadingSurface.new(new_vertices, model)
        shading_surface.setName("#{roof_surface.name} - #{Constants.ObjectNameEaves}")
        shading_surface.setShadingSurfaceGroup(shading_surface_group)
        
      end
      
    end

    shading_surfaces_to_remove = []
    shading_surfaces_to_add = []
=begin    
    model.getShadingSurfaces.each do |eave_1|
    
      vertices_1 = eave_1.vertices
    
      model.getShadingSurfaces.each do |eave_2|
        
        next if eave_1 == eave_2
        
        vertices_2 = eave_2.vertices
        
        vertex_1 = vertices_1[-1]
        vertex_2 = nil
        vertices_1.each do |point_1|
          vertex_2 = point_1
          distance_1 = Math.sqrt((vertex_1.x - vertex_2.x) ** 2 + (vertex_1.y - vertex_2.y) ** 2)
          next unless (distance_1 - eaves_depth).abs < 0.001 # get the vertices of the short side
          next unless vertices_2.include? vertex_1 and vertices_2.include? vertex_2
          shading_surfaces_to_remove << eave_1
          shading_surfaces_to_remove << eave_2
          vertices = vertices_1 + vertices_2.reverse
          vertices.each do |vertex|
            next if vertices.count(vertex) == 1
            vertices.delete(vertex)
          end
          shading_surfaces_to_add << vertices
          vertex_1 = vertex_2
        end
        
      end
    end

    eliminate overlapping of eaves
    model.getShadingSurfaces.each do |eave_1|
      model.getShadingSurfaces.each do |eave_2|
        next if eave_1 == eave_2
        new_eave_1 = OpenStudio::Point3dVector.new
        eave_1.vertices.each do |vertex|
          new_eave_1 << OpenStudio::Point3d.new(vertex.x, vertex.y, 0)
        end
        new_eave_2 = OpenStudio::Point3dVector.new
        eave_2.vertices.each do |vertex|
          new_eave_2 << OpenStudio::Point3d.new(vertex.x, vertex.y, 0)
        end
        next unless OpenStudio::intersects(new_eave_1, new_eave_2, 0.001)
      end
    end

    # remove interior eaves
    model.getShadingSurfaces.each do |shading_surface_1|

      points_1 = shading_surface_1.vertices
      model.getShadingSurfaces.each do |shading_surface_2|
      
        next if shading_surface_1 == shading_surface_2

        total = 0
      
        points_2 = shading_surface_2.vertices
        points_2.each do |point_2|
        
          zero_distance_to_segments = 0
        
          vertex_1 = points_1[-1]
          points_1.each do |point_1|
          
            vertex_2 = point_1
            
            if OpenStudio::getDistancePointToLineSegment(point_2, [vertex_1, vertex_2]) == 0
              zero_distance_to_segments += 1
            end
            
            vertex_1 = vertex_2
          
          end

          if zero_distance_to_segments > 0
            total += 1
          end
        
        end

        if total >= 2 # FIXME
          shading_surfaces_to_remove << shading_surface_2
        end
      
      end
    
    end
=end
    shading_surfaces_to_remove.uniq.each do |shading_surface|
      shading_surface.remove
    end

    shading_surfaces_to_add.uniq.each do |vertices|
      shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
      shading_surface.setName("Merged - #{Constants.ObjectNameEaves}")
      shading_surface.setShadingSurfaceGroup(shading_surface_group)       
    end

    unless surfaces_modified
      runner.registerAsNotApplicable("No surfaces found for adding eaves.")
      return true
    end
    
    shading_surface_group.shadingSurfaces.each do |shading_surface|
      runner.registerInfo("Added #{shading_surface.name}")
    end
    
    return true
    
  end
  
  def get_existing_eaves_depth(shading_surface)
    existing_eaves_depth = 0
    min_xs = []
    (0..3).to_a.each do |i|
      if (shading_surface.vertices[0].x - shading_surface.vertices[i].x).abs > existing_eaves_depth
        min_xs << (shading_surface.vertices[0].x - shading_surface.vertices[i].x).abs
      end
    end
    unless min_xs.empty?
      return min_xs.min
    end
    return 0
  end
  
end

# register the measure to be used by the application
CreateResidentialEaves.new.registerWithApplication

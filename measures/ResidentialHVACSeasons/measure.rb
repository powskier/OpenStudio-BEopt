# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessHVACSeasons < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACSeasons"
  end

  # human readable description
  def description
    return "This measure sets the heating and cooling season schedules if they differ from the HSP seasons."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure sets comma-separated strings, representing heating and cooling season schedules, on the BuildingUnit object when the user indicates not to use the HSP seasons."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a bool argument for using hsp seasons or not
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("use_hsp_seasons", true)
    arg.setDisplayName("Use HSP Seasons")
    arg.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    arg.setDefaultValue(true)
    args << arg
    
    #make a choice argument for months of the year
    month_display_names = OpenStudio::StringVector.new
    month_display_names << "Jan"
    month_display_names << "Feb"
    month_display_names << "Mar"
    month_display_names << "Apr"
    month_display_names << "May"
    month_display_names << "Jun"
    month_display_names << "Jul"
    month_display_names << "Aug"
    month_display_names << "Sep"
    month_display_names << "Oct"
    month_display_names << "Nov"
    month_display_names << "Dec"
    
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("heating_start_month", month_display_names, false)
    arg.setDisplayName("Heating Start Month")
    arg.setDescription("Start month of the heating season.")
    arg.setDefaultValue("Jan")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("heating_end_month", month_display_names, false)
    arg.setDisplayName("Heating End Month")
    arg.setDescription("End month of the heating season.")
    arg.setDefaultValue("Dec")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("cooling_start_month", month_display_names, false)
    arg.setDisplayName("Cooling Start Month")
    arg.setDescription("Start month of the cooling season.")
    arg.setDefaultValue("Jan")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("cooling_end_month", month_display_names, false)
    arg.setDisplayName("Cooling End Month")
    arg.setDescription("End month of the cooling season.")
    arg.setDefaultValue("Dec")
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
    
    use_hsp_seasons = runner.getBoolArgumentValue("use_hsp_seasons",user_arguments)

    return true if use_hsp_seasons
    
    month_map = {"Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>10, "Nov"=>11, "Dec"=>12}
    
    heating_start_month = runner.getOptionalStringArgumentValue("heating_start_month",user_arguments)
    heating_end_month = runner.getOptionalStringArgumentValue("heating_end_month",user_arguments)
    cooling_start_month = runner.getOptionalStringArgumentValue("cooling_start_month",user_arguments)
    cooling_end_month = runner.getOptionalStringArgumentValue("cooling_end_month",user_arguments)
    
    if heating_start_month.is_initialized
      heating_start_month = month_map[heating_start_month.get]
    end
    if heating_end_month.is_initialized
      heating_end_month = month_map[heating_end_month.get]
    end
    if cooling_start_month.is_initialized
      cooling_start_month = month_map[cooling_start_month.get]
    end
    if cooling_end_month.is_initialized
      cooling_end_month = month_map[cooling_end_month.get]
    end    
    
    heating_season = Array.new(heating_start_month-1, 0) + Array.new(heating_end_month-heating_start_month+1, 1) + Array.new(12-heating_end_month, 0)
    cooling_season = Array.new(cooling_start_month-1, 0) + Array.new(cooling_end_month-cooling_start_month+1, 1) + Array.new(12-cooling_end_month, 0)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
    
      unit.setFeature(Constants.SeasonHeating, heating_season.join(", "))
      unit.setFeature(Constants.SeasonCooling, cooling_season.join(", "))
    
    end

    return true

  end
  
end

# register the measure to be used by the application
ProcessHVACSeasons.new.registerWithApplication

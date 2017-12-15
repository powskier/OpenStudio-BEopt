require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'json'

class WorkflowTest < MiniTest::Test

  def test_osw
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    run_and_check("create-model-example.osw", parent_dir)
  end

  private
  
  def run_and_check(in_osw, parent_dir)
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    os_cli = os_clis[-1]
    
    # Run energy_rating_index workflow
    command = "cd #{parent_dir} && \"#{os_cli}\" run -w #{in_osw}"
    system(command)
  
    # Check all output files exist
    out_osw = File.join(parent_dir, "out.osw")
    assert(File.exists?(out_osw))
    
    # Check workflow was successful
    data_hash = JSON.parse(File.read(out_osw))
    assert_equal(data_hash["completed_status"], "Success")
  end
    
end

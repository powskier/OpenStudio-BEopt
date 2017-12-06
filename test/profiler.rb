require 'optparse'
require 'fileutils'

def profile(measure, test, name)

  unless File.directory?("./test/profiles")
    FileUtils.mkdir_p("./test/profiles")
  end

  system("ruby-prof -p multi -f ./test/profiles measures/#{measure}/tests/#{test} -- -n #{name}")

end

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby test/profiler.rb [-m] <measure_name> [-t] <test_file> [-n] <test_name>'

  options[:measure_name] = nil
  opts.on('-m', '--measure_name <name>', 'name of the test') do |name|
    options[:measure_name] = name
  end
  
  options[:test_file] = nil
  opts.on('-t', '--test_file <file>', 'name of the test') do |file|
    options[:test_file] = file
  end
  
  options[:test_name] = nil
  opts.on('-n', '--test_name <name>', 'name of the test') do |name|
    options[:test_name] = name
  end
  
  opts.on_tail('-h', '--help', 'display help') do
    puts opts
    exit
  end
end

optparse.parse!

profile(options[:measure_name], options[:test_file], options[:test_name])
#!/usr/bin/env ruby

require 'yaml'

# Monkeypatch a useful floating point rounding funciton into Float
class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

# Load global params
globals = YAML.load_file(ARGV[0])

# Load input data sets
inputdata = YAML.load_file(ARGV[1])

# For each input set
inputdata.each do |name, params|
  # loop through ionization values
  ionization = globals['rlogxi']['lower']
  resultset = []
  while ionization <= globals['rlogxi']['upper'] + 1e-9 # bloody floating point (in)accuracy!
    # Build xstar command line
    cmd = "xstar "
    globals['constants'].each_pair do |key, val|
      cmd << "#{key}=#{val} "
    end
    cmd << "modelname=#{name}_output "
    cmd << "spectrum_file=#{params['file']} "
    cmd << "rlrad38=#{params['luminosity']} "
    cmd << "rlogxi=#{ionization} "
    # Run xstar and capture output
    puts cmd
    puts "Running..."
    output = `#{cmd}`
    puts "Done..."
    output = output.split("\n")
    # Extract temperature value from output
    # Find first line with non-zero number in seventh position
    temperature = 0
    output.each do |line|
      nums = line.split(" ")
      temperature = nums[6].to_f
      break if temperature != 0
    end
    # Store temperature in result set, rounding off inconvenient tiny float bits
    resultset << [ionization.round_to(10), temperature]
    # Move to next ionization level
    ionization += globals['rlogxi']['step']
  end
  # Transform ionization parameters in result set
  resultset.each do |x|
    x[0] = Math.log10((0.961e4 * (10 ** x[0])) / (10 ** x[1]))
  end
  # Write result set to file
  File.open("#{name}_result.qdp", "w") do |file|
    resultset.each do |x|
      file << "#{x[0]}\t#{x[1]}\n"
    end
  end
end

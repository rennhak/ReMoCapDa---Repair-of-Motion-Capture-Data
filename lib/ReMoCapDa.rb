#!/usr/bin/ruby19
#


# System
require 'optparse' 
require 'optparse/time' 
require 'ostruct'
require 'yaml'

# System Extensions
require 'rubygems'

# Custom
$:.push('.')
require 'Logger'
require 'Repair'

# From MotionX - FIXME: Use MotionX's XYAML interface
$:.push('../base/MotionX/src/plugins/vpm/src')
require 'ADT.rb'


# ReMoCapDa class is a CLI interface for the sa library
class ReMoCapDa # {{{

  # ReMoCapDa Constructor
  #
  # @param [OpenStruct] options Object returned from the ReMoCapDa::parse_cmd_arguments function
  def initialize options = nil # {{{
    @options              = options

    # Minimal configuration
    @config               = OpenStruct.new
    @config.archive_dir   = "archive"
    @config.cache_dir     = "cache"

    @logger               = Utils::Logger.new( @options )

    unless( options.nil? ) # {{{
      @logger.message( :success, "Starting #{__FILE__} run" )
      @logger.message( :info, "Colorizing output as requested" ) if( @options.colorize )

      ####
      #
      # Main Control Flow
      #
      ##########



      @logger.message( :info, "Using the file (#{@options.input_filename.to_s}) as input" )
      @logger.message( :info, "Using the file (#{@options.output_filename.to_s}) as output" )

      # Crop Input Motion Data
      crop if( @options.crop )

      # Extract yaml config from input motion file
      extract_config if( @options.extract_config )

      # Repair input motion file with yaml config
      repair_input if( @options.repair_input )


      @logger.message( :success, "Finished #{__FILE__} run" )
    end # of unless( options.nil? ) }}}

  end # }}}


  # @fn         def extract_config # {{{
  # @brief      Extracts yaml config file from input motion for given frames
  def extract_config

    # Sanity check guards
    raise ArgumentError, "Input filename cannot be nil" if( @options.input_filename.nil? )
    raise ArgumentError, "Output filename cannot be nil" if( @options.output_filename.nil? )
    raise ArgumentError, "We cannot extract a yaml config and have -y given at the same time!" unless( @options.tpose_yaml_filename.nil? )
    raise ArgumentError, "From frame cannot be nil" if( @options.from.nil? )
    raise ArgumentError, "To frame cannot be nil" if( @options.to.nil? )
    raise ArgumentError, "Output file should end in the file extension .yaml" unless( @options.output_filename.split(".").last.to_s == "yaml" )

    @logger.message( :info, "Extracting yaml config from input (#{@options.input_filename.to_s}) and outputting it to (#{@options.output_filename}) for frames (#{@options.from.to_s}, #{@options.to.to_s})" )

    @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
    @input                      = ADT.new( @options.input_filename.to_s )

    # take all potential t-pose frames and calculate average
    @logger.message( :info, "For calculations, cropping to provided frame range" )
    @input.crop( @options.from, @options.to )

    # Create average pose from all input input markers (maybe not a good idea?)
    @input.combine

    # Localize all coordinates to pt30
    @input.local_coordinate_system( :pt30 )

    # store current marker information in yaml for later
    segments = Hash.new
    @input.segments.each do |segment|
      segments[ segment.to_s ] = Hash.new if( segments[ segment.to_s ].nil? )

      # %w[xtran ytran ztran  ].each do |i|
      order = @input.instance_variable_get( "@#{segment.to_s}" ).order

      order.each do |i|
        s         = @input.instance_variable_get( "@#{segment.to_s}" )
        i_array   = ( s.instance_variable_get( "@#{i.to_s}" ) )

        raise ArgumentError, "i_array can only be 1 long" unless( i_array.length <= 1 )

        value = i_array.first
        value = 0.0 if( i_array.length == 0 )

        segments[ segment.to_s ][ i.to_s ] = value
      end
    end

    yaml = segments.to_yaml

    # store this data to yaml
    @logger.message( :info, "Writing file" )
    File.open( @options.output_filename.to_s, "w" ) { |f| f.write( yaml ) }

    @logger.message( :success, "Finished writing of yaml - success" )
    exit
  end # of def extract_config # }}}


  # @fn         def repair_input # {{{
  # @brief      Repair input takes a motion stream and yaml config and tries to repair it.
  def repair_input

    # Sanity check guards
    raise ArgumentError, "Input filename cannot be nil" if( @options.input_filename.nil? )
    raise ArgumentError, "Output filename cannot be nil" if( @options.output_filename.nil? )
    raise ArgumentError, "Yaml config filename cannot be nil" if( @options.tpose_yaml_filename.nil? )
    raise ArgumentError, "T-Pose frame range must be nil" unless( @options.tpose.nil? )

    @logger.message( :info, "Repairing motion stream (#{@options.input_filename.to_s}) using the repair config (#{@options.tpose_yaml_filename.to_s}) and outputting it to (#{@options.output_filename})" )

    # Take input config and load
    yaml = read_config( @options.tpose_yaml_filename )

    # Determine threshhold of whats ok
    # threshhold = 2.5
    threshhold = 10

    @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
    @input                      = ADT.new( @options.input_filename.to_s )

    # Localize all coordinates to pt30
    @input.local_coordinate_system( :pt30 )

    @logger.message( :info, "Repairing the motion capture data" )
    repair = Repair.new( @logger, yaml, threshhold )
    @input = repair.run( @input )

    # Localize all coordinates to pt30
    @input.local_coordinate_system_undo( :pt30 )

    # Store result to disk
    @logger.message( :info, "Writing file" )
    @input.write( @options.output_filename.to_s )

    @logger.message( :success, "Finished, exiting" )
  end # of def repair_input # }}}


  # @fn         def crop # {{{
  # @brief      Crop takes a input and crops out given a specific frame region and outputs the result to a give output file
  def crop

    # Sanity check guards
    raise ArgumentError, "Input filename cannot be nil" if( @options.input_filename.nil? )
    raise ArgumentError, "Output filename cannot be nil" if( @options.output_filename.nil? )
    raise ArgumentError, "Yaml config filename must be nil" unless( @options.tpose_yaml_filename.nil? )
    raise ArgumentError, "From frame cannot be nil" if( @options.from.nil? )
    raise ArgumentError, "To frame cannot be nil" if( @options.to.nil? )

    @logger.message( :info, "Cropping motion stream (#{@options.input_filename.to_s}) from (#{@options.from.to_s}) to (#{@options.to.to_s}) and outputting it to (#{@options.output_filename})" )

    @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
    @input                      = ADT.new( @options.input_filename.to_s )

    # MotionX Needs fixing for this to work
    @logger.message( :info, "Cropping" )
    @input.crop( @options.from, @options.to )
    @logger.message( :info, "Writing file" )
    @input.write( @options.output_filename.to_s )

    @logger.message( :success, "Finished, exiting" )
    exit
  end # of def crop # }}}


  # Reads a YAML config
  #
  # @param    [String]      filename    String, representing the filename and path to the config file
  # @returns  [OpenStruct]              Returns an openstruct containing the contents of the YAML read config file (uses the feature of Extension.rb)
  def read_config filename # {{{

    # Pre-condition check
    raise ArgumentError, "Filename argument should be of type string, but it is (#{filename.class.to_s})" unless( filename.is_a?(String) )

    # Main
    @logger.message :debug, "Loading this config file: #{filename.to_s}"
    result = File.open( filename, "r" ) { |file| YAML.load( file ) }                 # return proc which is in this case a hash
    result = hashes_to_ostruct( result ) 

    # Post-condition check
    raise ArgumentError, "The function should return an OpenStruct, but instead returns a (#{result.class.to_s})" unless( result.is_a?( OpenStruct ) )

    result
  end # }}}


  # This function turns a nested hash into a nested open struct
  #
  # @author Dave Dribin
  # Reference: http://www.dribin.org/dave/blog/archives/2006/11/17/hashes_to_ostruct/
  #
  # @param    [Object]    object    Value can either be of type Hash or Array, if other then it is returned and not changed
  # @returns  [OStruct]             Returns nested open structs
  def hashes_to_ostruct object # {{{

    return case object
    when Hash
      object = object.clone
      object.each { |key, value| object[key] = hashes_to_ostruct(value) }
      OpenStruct.new( object )
    when Array
      object = object.clone
      object.map! { |i| hashes_to_ostruct(i) }
    else
      object
    end

  end # of def hashes_to_ostruct }}}



  # @fn         def parse_cmd_arguments( args ) # {{{
  # @brief      The function 'parse_cmd_arguments' takes a number of arbitrary commandline arguments and parses them into a proper data structure via optparse
  #
  # @param      [STDIN]       args    Ruby's STDIN.ARGS from commandline
  # @return     [OpenStruct]          Ruby optparse package options ostruct object
  def parse_cmd_arguments( args )

    raise ArgumentError, "Argument provided cannot be empty" if( (args == "") or (args.nil?) )

    options                         = OpenStruct.new

    # Define default options
    options.verbose                 = false
    options.colorize                = false
    options.debug                   = false
    options.quiet                   = false
    options.tpose                   = nil # frame range
    options.tpose_yaml_filename     = nil # input  | only yaml config
    options.input_filename          = nil # input  | motion data
    options.output_filename         = nil # output | motion data OR yaml config

    options.from                    = nil
    options.to                      = nil

    # Boolean swtiches for control flow
    options.crop                    = false
    options.extract_config          = false
    options.repair_input            = false

    pristine_options                = options.dup

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

      # Boolean
      opts.on( "-x", "--crop", "Crop Input Motion stream (needs also --from and --to)" ) { |crop| options.crop = crop }

      opts.on( "-f", "--from OPT", "From frame" ) { |frame| options.from = frame.to_i }
      opts.on( "-t", "--to OPT", "To frame" ) { |frame| options.to = frame.to_i }

      opts.on( "-e", "--extract-config", "Extract config yaml from input data (needs also --tpose)" ) { |c| options.extract_config = c }
      opts.on( "-r", "--repair-input", "Repair input motion file (nees also extracted yaml config)" ) { |c| options.repair_input = c }


      opts.on( "-y", "--yaml OPT", "T-Pose YAML Config file (including path) to the extracted body data" ) { |filename| options.tpose_yaml_filename = filename }
      opts.on( "-i", "--input OPT", "Input VPM file (including path)" ) { |filename| options.input_filename = filename }
      opts.on( "-o", "--output OPT", "Output file (including path)" ) { |filename| options.output_filename = filename }

      opts.separator ""
      opts.separator "Specific options:"

      opts.on( "-v", "--verbose", "Run verbosely") { |verbose| options.verbose = verbose }
      opts.on( "-q", "--quiet", "Run quietly, don't output much") { |quiet| options.quiet = quiet }
      opts.on( "-d", "--debug", "Print verbose output and more debugging") { |debug| options.debug = debug }

      opts.separator ""
      opts.separator "Common options:"

      opts.on( "-c", "--colorize", "Colorizes the output of the script for easier reading") { |colorize| options.colorize = colorize }

      opts.on_tail("-h", "--help", "Show this message") { puts opts; exit }
      opts.on_tail("--version", "Show version") { puts OptionParser::Version.join('.'); exit }
    end # of opts = OptionParser.new do |opts|

    opts.parse!(args)

    options
  end # of parse_cmd_arguments }}}

end # of class ReMoCapDa }}}


# Direct Invocation
if __FILE__ == $0 # {{{

  options               = ReMoCapDa.new.parse_cmd_arguments( ARGV )
  remocapda             = ReMoCapDa.new( options )

end # of if __FILE__ == $0 # }}}


# vim:ts=2:tw=100:wm=100


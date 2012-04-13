#!/usr/bin/ruby19
#


# System
require 'optparse' 
require 'optparse/time' 
require 'ostruct'

# System Extensions
require 'rubygems'

# Custom
$:.push('.')
require 'Logger'

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
    raise ArgumentError, "T-Pose frame range cannot be nil" if( @options.tpose.nil? )

    @logger.message( :info, "Extracting yaml config from input (#{@options.input_filename.to_s}) and outputting it to (#{@options.output_filename}) for frames (#{@options.tpose.join( ', ')})" )

    @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
    @input                      = ADT.new( @options.input_filename.to_s )

    # take all frames and calculate average
    


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

  end # of def repair_input # }}}


  # @fn         def crop # {{{
  # @brief      Crop takes a input and crops out given a specific frame region and outputs the result to a give output file
  def crop
    @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
    @input                      = ADT.new( @options.input_filename.to_s )

    raise NotImplementedError

    # MotionX Needs fixing for this to work
    @logger.message( :info, "Cropping" )
    # This one is borked - look at ADT::processSegment
    # @adt.crop( 1, 3 )
    # @logger.message( :info, "Writing file" )
    # input.write( "/tmp/foobar.vpm" )

  end # of def crop # }}}


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

    # Boolean swtiches for control flow
    options.crop                    = false
    options.extract_config          = false
    options.repair_input            = false

    pristine_options                = options.dup

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

      opts.on( "-t", "--tpose OPT", "T-Pose frame used for calibration (needs frame number as argument, e.g. OPT := \"5-42\")" ) do |frame|
        # check that we only get 1 "-" not more
        if( frame.scan("-").length != 1 )
          puts "Couldn't understand the -t input, please check help for information on the formatting"
          exit
        else
          tmp               = frame.split("-")
          first, second     = tmp.first.to_i, tmp.last.to_i

          if( first == 0 or second == 0 )
            puts "Parameters can only be Numeric or start from 1"
            exit
          end

          if( tmp.first.to_i > tmp.last.to_i )
            puts "First parameter of -t must be smaller than the second one"
            exit
          end
        end

        options.tpose = ( frame.split( "-" ) ).collect!{ |n| n.to_i }
      end

#      opts.on( "--crop OPT", "Crop frames from input stream and send to output file (e.g. OPT := \"5-42\")" ) do |frame|
#        # check that we only get 1 "-" not more
#        if( frame.scan("-").length != 1 )
#          puts "Couldn't understand the --crop input, please check help for information on the formatting"
#          exit
#        else
#          tmp               = frame.split("-")
#          first, second     = tmp.first.to_i, tmp.last.to_i
#
#          if( first == 0 or second == 0 )
#            puts "Parameters can only be Numeric or start from 1"
#            exit
#          end
#
#          if( tmp.first.to_i > tmp.last.to_i )
#            puts "First parameter of -t must be smaller than the second one"
#            exit
#          end
#        end
#
#        options.tpose = ( frame.split( "-" ) ).collect!{ |n| n.to_i }
#      end


      # Boolean
      opts.on( "-x", "--crop", "Crop Input Motion stream (needs also --from and --to)" ) { |crop| options.crop = crop }
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


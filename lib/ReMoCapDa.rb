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

      unless( @options.input_filename.nil? or @options.output_filename.nil? or @options.tpose.nil? )
        @logger.message( :info, "Using the file (#{@options.input_filename.to_s}) as input" )
        @logger.message( :info, "Using the file (#{@options.output_filename.to_s}) as output" )
        @logger.message( :info, "Got T-Pose frame from CLI (#{@options.tpose.to_s})" )


        # @logger.message( :info, "Loading tpose input into MotionX VPM Plugin ADT format" )
        # @tpose                      = ADT.new( @options.tpose_input_filename.to_s )

        @logger.message( :info, "Loading input into MotionX VPM Plugin ADT format" )
        @input                      = ADT.new( @options.input_filename.to_s )

        #@logger.message( :info, "Cropping" )
        # This one is borked - look at ADT::processSegment
        # @adt.crop( 1, 3 )
        # @logger.message( :info, "Writing file" )
        #@input.write( "/tmp/foobar.vpm" )

        @logger.message( :info, "Extracting T-Pose geometry" )
        

      end

      @logger.message( :success, "Finished #{__FILE__} run" )
    end # of unless( options.nil? ) }}}

  end # }}}


  # @fn     def parse_cmd_arguments( args ) # {{{
  # @brief  The function 'parse_cmd_arguments' takes a number of arbitrary commandline arguments and parses them into a proper data structure via optparse
  #
  # @param  [STDIN]       args    Ruby's STDIN.ARGS from commandline
  # @return [OpenStruct]          Ruby optparse package options ostruct object
  def parse_cmd_arguments( args )

    raise ArgumentError, "Argument provided cannot be empty" if( (args == "") or (args.nil?) )

    options               = OpenStruct.new

    # Define default options
    options.verbose         = false
    options.clean           = false
    options.cache           = false
    options.colorize        = false
    options.debug           = false
    options.quiet           = false
    options.tpose           = nil
    options.tpose_input_filename = nil
    options.input_filename  = nil
    options.output_filename = nil

    pristine_options        = options.dup

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

      opts.on( "-t", "--tpose OPT", "T-Pose frame used for calibration (needs frame number as argument)" ) { |frame| options.tpose = frame }
      opts.on( "-p", "--tpose-input OPT", "T-Pose Input VPM file (including path)" ) { |filename| options.tpose_input_filename = filename }
      opts.on( "-i", "--input OPT", "Input VPM file (including path)" ) { |filename| options.input_filename = filename }
      opts.on( "-o", "--output OPT", "Output VPM file (including path)" ) { |filename| options.output_filename = filename }

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-v", "--verbose", "Run verbosely") { |verbose| options.verbose = verbose }
      opts.on("-q", "--quiet", "Run quietly, don't output much") { |quiet| options.quiet = quiet }
      opts.on( "--debug", "Print verbose output and more debugging") { |debug| options.debug = debug }

      opts.separator ""
      opts.separator "Common options:"

      opts.on("-c", "--colorize", "Colorizes the output of the script for easier reading") { |colorize| options.colorize = colorize }
      opts.on("-u", "--use-cache", "Use cached/archived files instead of processing again") { |use_cache| options.cache = use_cache }
      opts.on( "--clean", "Cleanup after the script and remove things not needed") { |clean| options.clean = clean }

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


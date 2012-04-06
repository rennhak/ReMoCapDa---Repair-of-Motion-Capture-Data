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

    pristine_options        = options.dup

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

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


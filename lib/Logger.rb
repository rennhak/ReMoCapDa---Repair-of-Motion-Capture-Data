#!/usr/bin/ruby19
#


# System
require 'optparse' 
require 'optparse/time' 
require 'ostruct'


# {{{

module Utils # {{{

  class Logger # {{{

    def initialize options = nil # {{{
      @options = options
    end  # }}}


    # @fn     def colorize color, message # {{{
    # @brief  The function colorize takes a message and wraps it into standard color commands such as for baih.
    # @param  [String] color   The colorname in plain english. e.g. "LightGray", "Gray", "Red", "BrightRed"
    # @param  [String] message The message which should be wrapped
    # @return [String] Colorized message string
    # @note   This might not work for your terminal
    #
    # Black       0;30     Dark Gray     1;30
    # Blue        0;34     Light Blue    1;34
    # Green       0;32     Light Green   1;32
    # Cyan        0;36     Light Cyan    1;36
    # Red         0;31     Light Red     1;31
    # Purple      0;35     Light Purple  1;35
    # Brown       0;33     Yellow        1;33
    # Light Gray  0;37     White         1;37
    def colorize color, message 

      colors  = {
        "Gray"        => "\e[1;30m",
        "LightGray"   => "\e[0;37m",
        "Cyan"        => "\e[0;36m",
        "LightCyan"   => "\e[1;36m",
        "Blue"        => "\e[0;34m",
        "LightBlue"   => "\e[1;34m",
        "Green"       => "\e[0;32m",
        "LightGreen"  => "\e[1;32m",
        "Red"         => "\e[0;31m",
        "LightRed"    => "\e[1;31m",
        "Purple"      => "\e[0;35m",
        "LightPurple" => "\e[1;35m",
        "Brown"       => "\e[0;33m",
        "Yellow"      => "\e[1;33m",
        "White"       => "\e[1;37m",
        "NoColor"     => "\e[0m"
      }

      raise ArgumentError, "Function arguments cannot be nil" if( color.nil? or message.nil? )
      raise ArgumentError, "Unknown color" unless( colors.keys.include?( color ) )

      colors[ color ] + message + colors[ "NoColor" ]
    end # of def colorize }}}


    # @fn     def message level, msg, colorize = @options.colorize # {{{
    # @brief  The function message will take a message as argument as well as a level (e.g. "info", "ok", "error", "question", "debug") which then would print 
    #         ( "(--) msg..", "(II) msg..", "(EE) msg..", "(??) msg..")
    # @param  [Symbol] level Ruby symbol, can either be :info, :success, :error or :question
    # @param  [String] msg String, which represents the message you want to send to stdout (info, ok, question) stderr (error)
    #
    # Helpers: colorize
    def message level, msg, colorize = @options.colorize

      symbols = {
        :info      => [ "(--)", "Brown"       ],
        :success   => [ "(II)", "LightGreen"  ],
        :warning   => [ "(WW)", "Yellow"      ],
        :error     => [ "(EE)", "LightRed"    ],
        :question  => [ "(??)", "LightCyan"   ],
        :debug     => [ "(++)", "LightBlue"   ]
      }

      raise ArugmentError, "Can't find the corresponding symbol for this message level (#{level.to_s}) - is the spelling wrong?" unless( symbols.key?( level )  )

      print = []

      output = ( level == :error ) ? ( "STDERR.puts" ) : ( "STDOUT.puts" )
      print << output
      print << "colorize(" if( colorize )
      print << "\"" + symbols[ level ].last + "\"," if( colorize )
      print << "\"#{symbols[ level ].first.to_s} #{msg.to_s}\""
      print << ")" if( colorize )

      print.clear if( @options.quiet )

      eval( print.join( " " ) )

    end # of def message }}}

  end # of class Logger }}}

end # of module Utils # }}}


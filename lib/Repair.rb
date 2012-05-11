#!/usr/bin/ruby
#

###
#
# File: Repair.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Repair.rb
# @author     Bjoern Rennhak
#
#######


# Libaries
$:.push('.')
require 'Helpers.rb'

# Repair modules
$:.push('modules')
require 'Head.rb'
require 'Hands.rb'


# @class      class Repair # {{{
# @brief      The class Repair takes motion capture data and checks if some markers are broken. If so it tries to repair it.
#             Umbrella class to use individual repair modules.
class Repair

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Repair class
  #
  # @param    [OpenStruct]    options       OpenStruct containing the result of the CLI argument parsing
  # @param    [Logger]        logger        Logger class
  # @param    [OpenStruct]    yaml          OpenStruct containing the loaded yaml
  # @param    [Fixnum]        threshhold    Threshhold for the repair detection
  def initialize options = nil, logger = nil, yaml = nil, threshhold = nil

    # Sanity check
    raise ArgumentError, "Options can't be nil" if( options.nil? )
    raise ArgumentError, "Logger can't be nil" if( logger.nil? )
    raise ArgumentError, "Yaml can't be nil" if( yaml.nil? )
    raise ArgumentError, "Threshhold can't be nil" if( threshhold.nil? )
    raise ArgumentError, "No Modules to repair given by commandline (-m)" if( options.modules.empty? )

    @logger       = logger
    @yaml         = yaml
    @threshhold   = threshhold

    # Go through markers and correct where incorrect 0..n
    @keys         = yaml.instance_variable_get("@table").keys

    # Repair modules
    @head, @hands = nil, nil

    if( options.modules.include?( "head" ) )
      @head         = Head.new( logger, yaml, threshhold )
      @logger.message :info, "Going to repair the HEAD"
    end

    if( options.modules.include?( "hands" ) )
      @hands        = Hands.new( logger, yaml, threshhold )
      @logger.message :info, "Going to repair the HANDS"
    end
  end # of def initialize }}}


  # @fn       def run # {{{
  # @brief    Run checks the motion data for problems and tries to repair it
  #
  # @param    [ADT]     motion_capture_data       Motion Capture class MotionX::ADT
  def run motion_capture_data = nil

    # Sanity check
    raise ArgumentError, "Motion capture data cannot be nil" if( motion_capture_data.nil? )

    @logger.message( :info, "Running repair" )

    result    = motion_capture_data
    segments  = motion_capture_data.segments

    # Determine runtime of motion data
    frames    = ( motion_capture_data.instance_variable_get( "@#{segments.first.to_s}" ).frames ).to_i
    order     = ( motion_capture_data.instance_variable_get( "@#{segments.first.to_s}" ).order )

    # Iterate over the entire data
    0.upto( frames - 1 ) do |frame_index|

      # Create empty arrays for each segment, the array will hold the data for 1 frame
      data    = Hash.new
      segments.each { |segment| data[ segment.to_s ] = [] }

      # Extract the data for all segments for 1 frame
      segments.each do |segment|
        order.each do |o|
          value = eval( "motion_capture_data.#{segment.to_s}.#{o.to_s}[ #{frame_index.to_i} ]" )
          value = 0.0 if( value.nil? )

          data[ segment.to_s ] << value
        end
      end # of segments.each

      # Turn hash into proper ostruct
      data = Helpers.new.hashes_to_ostruct( data )

      @logger.message( :debug, "[ Frame: #{frame_index.to_s} ]" )

      unless( @head.nil? ) # {{{
        @logger.message( :debug, "\tChecking if head needs repair" )

        # Do checking and repair
        @head.set_markers( data.lfhd, data.lbhd, data.rfhd, data.rbhd, data.pt24 )

        if( @head.repair_head? )
          @logger.message( :warning, "Repairing head at frame (#{frame_index.to_s})" )

          lfhd, lbhd, rfhd, rbhd, pt24 = @head.repair_head!

          %w[lfhd lbhd rfhd rbhd pt24].each do |marker|
            eval( "motion_capture_data.#{marker.to_s}.xtran[ #{frame_index.to_i} ] = #{marker.to_s}[0]" )
            eval( "motion_capture_data.#{marker.to_s}.ytran[ #{frame_index.to_i} ] = #{marker.to_s}[1]" )
            eval( "motion_capture_data.#{marker.to_s}.ztran[ #{frame_index.to_i} ] = #{marker.to_s}[2]" )
          end
        end # of repair_head
      end # unless( @head.nil? ) # }}}

      unless( @hands.nil? ) # {{{
        @logger.message( :debug, "\tChecking if hand needs repair" )
        @hands.set_markers( data.rfin, data.rwra, data.rwrb, data.lfin, data.lwra, data.lwrb, data.lelb, data.relb )

        if( @hands.repair_hands? )
          @logger.message( :warning, "Repairing hand at frame (#{frame_index.to_s})" )

          rfin, rwra, rwrb, lfin, lwra, lwrb = @hands.repair_hands!

          %w[rfin rwra rwrb lfin lwra lwrb].each do |marker|
            eval( "motion_capture_data.#{marker.to_s}.xtran[ #{frame_index.to_i} ] = #{marker.to_s}[0]" )
            eval( "motion_capture_data.#{marker.to_s}.ytran[ #{frame_index.to_i} ] = #{marker.to_s}[1]" )
            eval( "motion_capture_data.#{marker.to_s}.ztran[ #{frame_index.to_i} ] = #{marker.to_s}[2]" )
          end

        end # of repair_hands
      end # unless( @hands.nil? ) # }}}

    end # of 0.upto( frames - 1 )

    # Return result
    result
  end # of def run # }}}

end # of class Repair }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100

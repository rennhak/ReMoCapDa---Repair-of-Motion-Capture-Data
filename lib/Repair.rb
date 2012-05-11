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
  # @param    [ADT]           data          Motion Capture class MotionX::ADT
  def initialize options = nil, logger = nil, yaml = nil, threshhold = nil, data = nil

    # Sanity check # {{{
    raise ArgumentError, "Options can't be nil" if( options.nil? )
    raise ArgumentError, "Logger can't be nil" if( logger.nil? )
    raise ArgumentError, "Yaml can't be nil" if( yaml.nil? )
    raise ArgumentError, "Threshhold can't be nil" if( threshhold.nil? )
    raise ArgumentError, "No Modules to repair given by commandline (-m)" if( options.modules.empty? )
    raise ArgumentError, "Motion capture data cannot be nil" if( data.nil? )
    # }}}

    @logger       = logger
    @yaml         = yaml
    @threshhold   = threshhold
    @data         = data

    # Go through markers and correct where incorrect 0..n
    @keys         = yaml.instance_variable_get("@table").keys

    # Repair modules
    @head, @hands = nil, nil

    if( options.modules.include?( "head" ) )
      @head       = Head.new( logger, yaml, threshhold )
      @logger.message :info, "Going to repair the HEAD"
    end

    if( options.modules.include?( "hands" ) )
      @hands      = Hands.new( logger, yaml, threshhold )
      @logger.message :info, "Going to repair the HANDS"
    end

    # p @scanned[ "hands" ].first  => [ true|false, data ostruct ]
    @scanned      = scan( @data )

  end # of def initialize }}}


  # @fn       def scan # {{{
  # @brief    Scans through the data to determine which parts need to be repaired
  #
  # @param    [ADT]     motion_capture_data       Motion Capture class MotionX::ADT
  def scan motion_capture_data = @data

    # Sanity check
    raise ArgumentError, "Motion capture data cannot be nil" if( motion_capture_data.nil? )

    @logger.message( :info, "Scanning data to determine what needs to be repaired" )

    result    = motion_capture_data
    segments  = motion_capture_data.segments

    repair    = Hash.new  # we store our boolean array's here

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

        repair[ "head" ] = [] if( repair[ "head" ].nil? )

        # Do checking and repair
        @head.set_markers( data.lfhd, data.lbhd, data.rfhd, data.rbhd, data.pt24 )

        repair[ "head" ][ frame_index ] = [ @head.repair_head?, data  ]
      end # unless( @head.nil? ) # }}}

      unless( @hands.nil? ) # {{{
        @logger.message( :debug, "\tChecking if hand needs repair" )
        repair[ "hands" ] = [] if( repair[ "hands" ].nil? )

        @hands.set_markers( data.rfin, data.rwra, data.rwrb, data.lfin, data.lwra, data.lwrb, data.lelb, data.relb )

        repair[ "hands" ][ frame_index ] = [ @hands.repair_hands?, data ]
      end # unless( @hands.nil? ) # }}}

    end # of 0.upto( frames - 1 )

    # Return result
    repair
  end # of def scan # }}}


  # @fn       def run # {{{
  # @brief    Run checks the motion data for problems and tries to repair it
  #
  # @param    [ADT]     motion_capture_data       Motion Capture class MotionX::ADT
  # @param    [Hash]    scanned                   Output from the scan function
  def run motion_capture_data = @data, scanned = @scanned

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

      # # Create empty arrays for each segment, the array will hold the data for 1 frame
      # data    = Hash.new
      # segments.each { |segment| data[ segment.to_s ] = [] }

      # # Extract the data for all segments for 1 frame
      # segments.each do |segment|
      #   order.each do |o|
      #    value = eval( "motion_capture_data.#{segment.to_s}.#{o.to_s}[ #{frame_index.to_i} ]" )
      #    value = 0.0 if( value.nil? )
      #
      #    data[ segment.to_s ] << value
      #  end
      # end # of segments.each

      # Turn hash into proper ostruct
      # data = Helpers.new.hashes_to_ostruct( data )

      @logger.message( :debug, "[ Repair Phase ][ Frame: #{frame_index.to_s} ]" )

      unless( @head.nil? ) # {{{
        broken_flag, data = scanned[ "head" ][ frame_index ]

        # Do checking and repair
        @head.set_markers( data.lfhd, data.lbhd, data.rfhd, data.rbhd, data.pt24 )

        if( broken_flag )
          @logger.message( :warning, "Repairing head at frame (#{frame_index.to_s})" )

          # Determine two frames before frame_index and two after frame_index which are OK
          frames                        = get_valid_frames( frame_index, scanned[ "head" ] )
          @head.set_repair_frames( frames )

          lfhd, lbhd, rfhd, rbhd, pt24  = @head.repair_head!

          %w[lfhd lbhd rfhd rbhd pt24].each do |marker|
            eval( "motion_capture_data.#{marker.to_s}.xtran[ #{frame_index.to_i} ] = #{marker.to_s}[0]" )
            eval( "motion_capture_data.#{marker.to_s}.ytran[ #{frame_index.to_i} ] = #{marker.to_s}[1]" )
            eval( "motion_capture_data.#{marker.to_s}.ztran[ #{frame_index.to_i} ] = #{marker.to_s}[2]" )
          end
        end # of repair_head
      end # unless( @head.nil? ) # }}}

      unless( @hands.nil? ) # {{{
        broken_flag, data = scanned[ "hands" ][ frame_index ]

        @hands.set_markers( data.rfin, data.rwra, data.rwrb, data.lfin, data.lwra, data.lwrb, data.lelb, data.relb )

        if( broken_flag )
          @logger.message( :warning, "Repairing hand at frame (#{frame_index.to_s})" )

          # Determine two frames before frame_index and two after frame_index which are OK
          frames                        = get_valid_frames( frame_index, scanned[ "hands" ] )
          @hands.set_repair_frames( frames )

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


  # @fn         def get_valid_frames index, data # {{{
  # @brief      Extracts two valid frame indexes before and after the given index which we can use to repair the given frame index.
  #
  # @param      [Fixnum]        index         Index which we want to repair. We need two frames before and two after this index which are OK.
  # @param      [Array]         data          Data array in the shape [ [broken_flag, data], [...], ...] where each element of array index represents the corresponding frame.
  #
  # @returns    [Array]                       Returns an array containing three other subarrays [ [before_frame_index1, index2], [index], [after_frame_index1, index2] ]
  def get_valid_frames index, data

    @logger.message( :debug, "Finding valid frames for index (#{index.to_s})" )

    amount        = 2

    before_frames = []
    self_frame    = [] << index
    after_frames  = []

    # get frames from before index which are ok
    ( index.to_i ).downto( 0 ) do |i|
      next if( i == index )
      break if( before_frames.length == amount )

      broken = data[i].first
      before_frames << i unless( broken )
    end

    # get frames from after index which are ok
    ( index.to_i ).upto( data.length.to_i - 1 ) do |i|
      next if( i == index )
      break if( after_frames.length == amount )


      broken = data[i].first
      puts "i (#{i.to_s}) broken? #{broken.to_s}"
      after_frames << i unless( broken )
    end

    # Corect the order to asc
    before_frames.sort!
    self_frame.sort!
    after_frames.sort!

    # Turn frame IDs into frame IDs + data

    before_frames.collect! do |frame|
      [ frame, data[ frame.to_i ].last ]
    end

    self_frame.collect! do |frame|
      [ frame, data[ frame.to_i ].last ]
    end

    after_frames.collect! do |frame|
      [ frame, data[ frame.to_i ].last ]
    end

    [ before_frames, self_frame, after_frames ]
  end # of def get_valid_frames index, data # }}}


end # of class Repair }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100

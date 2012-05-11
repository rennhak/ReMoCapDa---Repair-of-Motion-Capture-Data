#!/usr/bin/ruby
#

###
#
# File: Head.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Head.rb
# @author     Bjoern Rennhak
#
#######


# Libaries
$:.push('..')
require 'Helpers.rb'


# @class      class Head # {{{
# @brief      The class Head takes motion capture data and checks if some markers are broken. If so it tries to repair it.
class Head

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Head class
  #
  # @param    [Logger]        logger        Logger class
  # @param    [OpenStruct]    yaml          OpenStruct containing the loaded yaml
  # @param    [Fixnum]        threshhold    Threshhold for the repair detection
  def initialize logger = nil, yaml = nil, threshhold = nil

    # Sanity check
    raise ArgumentError, "Logger can't be nil" if( logger.nil? )
    raise ArgumentError, "Yaml can't be nil" if( yaml.nil? )
    raise ArgumentError, "Threshhold can't be nil" if( threshhold.nil? )

    @logger           = logger
    @yaml             = yaml
    @threshhold       = threshhold
    @helpers          = Helpers.new

    @logger.message :debug, "Using threshhold (#{threshhold.to_s})"

    # Go through markers and correct where incorrect 0..n
    @keys             = yaml.instance_variable_get("@table").keys
    @order            = [ "lf_lb", "rf_rb", "lf_rf", "lb_rb", "lf_rb", "lb_rf" ]

    reference         = [ @yaml.lfhd, @yaml.lbhd, @yaml.rfhd, @yaml.rbhd ]
    @yaml_frame_head  = get_lengths( *( reference.collect { |i| ostruct_to_array( i ) } ) )

    @frame_head       = nil

    @lfhd             = nil
    @lbhd             = nil
    @rfhd             = nil
    @rbhd             = nil
    @pt24             = nil

    @frames           = nil
  end # of def initialize }}}


  # @fn       def repair_head? lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold # {{{
  # @brief    Checks if the head markers need repairing
  #
  # @param    [Array]         lfhd            Left-Front Marker on the head. Array has the shape, xtran, ytran, ztran, etc.
  # @param    [Array]         lbhd            Left-Back Marker on the head.
  # @param    [Array]         rfhd            Right-Front Marker on the head.
  # @param    [Array]         rbhd            Right-Back Marker on the head.
  # @param    [Array]         pt24            P24 is calculated and in the center of all markers (center of head).
  # @param    [Fixnum]        threshhold      Threshhold is the value we accept as being still ok deviating from the T-Pose measurement (e.g. <10)
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def repair_head? lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold

    # Sanity check
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )
    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )

    # Main control flow
    result            = false

    # get lengths of current frame for the head
    @frame_head       = get_lengths( lfhd, lbhd, rfhd, rbhd )

    difference        = get_difference( @frame_head )

    result = true if( difference[ "sum" ] > threshhold )

    result
  end # of def repair_head? lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold # }}}


  # @fn       def get_difference frame = nil, reference_frame = @yaml_frame_head # {{{
  # @brief    Get difference takes the reference frame (t-pose) and the current frame and calculates
  #           the difference array for each corresponding markers as well as the sum of it for threshholding.
  #
  # @param    [Hash]        reference_frame     Reference frame is a hash containing all relevant head markers (from yaml)
  # @param    [Hash]        frame               Frame is a hash containing all relevant head markers (current frame) 
  #
  # @returns                                    The get_difference function returns a hash containing the difference of 
  #                                             each marker pair was well as the sum of differences stored by the
  #                                             "sum" key.
  def get_difference frame = nil, reference_frame = @yaml_frame_head
    # Sanity check
    raise ArgumentError, "reference_frame cannot be nil" if( reference_frame.nil? )
    raise ArgumentError, "frame cannot be nil" if( frame.nil? )
    raise ArgumentError, "reference_frame must be of type hash" unless( reference_frame.is_a?( Hash ) )
    raise ArgumentError, "frame must be of type hash" unless( frame.is_a?( Hash ) )
    raise ArgumentError, "Both hash key sets must align exactly" unless( reference_frame.keys == frame.keys )
    raise ArgumentError, "Both hash key sets cannot be empty" if( reference_frame.keys.empty? or frame.keys.empty? )

    # Main flow
    result            = Hash.new
    keys              = frame.keys

    keys.each { |marker| result[ marker.to_s ] = frame[ marker.to_s ] - reference_frame[ marker.to_s ] }

    difference_sum    = result.values.inject{ |sum, x| sum + x }
    result[ "sum" ]   = difference_sum

    result
  end # of def get_difference reference_frame = nil, frame = nil # }}}


  # @fn       def set_repair_frames array = nil # {{{
  # @brief    These data points 
  def set_repair_frames array = nil
    @frames = array
  end # of def set_repair_frames array = nil # }}}


  # @fn       def set_markers lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24 # {{{
  # @brief    Sets markers inside the class state
  #
  # @param    [Array]         lfhd            Left-Front Marker on the head. Array has the shape, xtran, ytran, ztran, etc.
  # @param    [Array]         lbhd            Left-Back Marker on the head.
  # @param    [Array]         rfhd            Right-Front Marker on the head.
  # @param    [Array]         rbhd            Right-Back Marker on the head.
  # @param    [Array]         pt24            P24 is calculated and in the center of all markers (center of head).
  # @param    [Fixnum]        threshhold      Threshhold is the value we accept as being still ok deviating from the T-Pose measurement (e.g. <10)
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def set_markers lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24
    @lfhd, @lbhd, @rfhd, @rbhd, @pt24 = lfhd, lbhd, rfhd, rbhd, pt24
  end # of def set_markers lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24 # }}}


  # @fn       def done? difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) ), threshhold = @threshhold, order = @order # {{{
  # @brief    Done takes the difference from the current to the reference coordinates (local) and if bigger than threshhold returns an array for each @order pair
  #
  # @param    [Hash]      difference        Output from the get_difference function
  # @param    [Fixnum]    threshhold        Threshhold provided at the instantiation of the class
  # @param    [Array]     order             Order of the pairs we evalutate
  #
  # @returns  [Array]                       Array, containing booleans in der order of the @order array
  def done? difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) ), threshhold = @threshhold, order = @order

    # holding false/true
    result = []
    values = []

    order.each do |marker|
      value = difference[ marker.to_s ].abs
      values << value

      if( value > threshhold )
        result << false   # value > threshhold --> this line is not good
      else
        result << true    # value < threshhold --> this line is good
      end

    end # of order.each do |marker|

    # p values
    # p result

    result
  end # def done? difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) ), threshhold = @threshhold, order = @order # }}}


  # @fn       def repair_head! lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold # {{{
  # @brief    Repairs head markers
  #
  # @param    [Array]         lfhd            Left-Front Marker on the head. Array has the shape, xtran, ytran, ztran, etc.
  # @param    [Array]         lbhd            Left-Back Marker on the head.
  # @param    [Array]         rfhd            Right-Front Marker on the head.
  # @param    [Array]         rbhd            Right-Back Marker on the head.
  # @param    [Array]         pt24            P24 is calculated and in the center of all markers (center of head).
  # @param    [Fixnum]        threshhold      Threshhold is the value we accept as being still ok deviating from the T-Pose measurement (e.g. <10)
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def repair_head! lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )
    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )

    # check repair frames
    before_frames    = @frames[0]
    self_frame       = @frames[1]
    after_frames     = @frames[2]

    @logger.message( :debug, "Before frames are fine, we have two valid ones" ) if( before_frames.length >= 2 )
    @logger.message( :warning, "Before frames are thin, we have ONLY one valid one" ) if( before_frames.length == 1 )
    @logger.message( :error, "We have no before frames, that means we cannot interpolate to repair" ) if( before_frames.length == 0 )

    raise ArgumentError, "There was some problem with the @frames, we don't have the self frame?!" unless( self_frame.length == 1 )

    @logger.message( :debug, "After frames are fine, we have two valid ones" ) if( after_frames.length >= 2 )
    @logger.message( :warning, "After frames are thin, we have ONLY one valid one" ) if( after_frames.length == 1 )
    @logger.message( :error, "We have no after frames, that means we cannot interpolate to repair" ) if( after_frames.length == 0 )


    # Iterate over markers until repaired
    @good_distance = done?
    while( @good_distance.include?( false ) )

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed (#{@good_distance.join( ", " )})" )

      if( @good_distance[0] )  # lfhd <-> lbhd is ok


        raise NotImplementedError

        # (A) lbhd ; (B) rbhd ; C = B-A ; 
        y_x1 = @yaml.lbhd.xtran
        y_y1 = @yaml.lbhd.ytran
        y_z1 = @yaml.lbhd.ztran

        y_x2 = @yaml.rbhd.xtran
        y_y2 = @yaml.rbhd.ytran
        y_z2 = @yaml.rbhd.ztran

        x1   = @lbhd[0]
        y1   = @lbhd[1]
        z1   = @lbhd[2]

        x2   = @rbhd[0]
        y2   = @rbhd[1]
        z2   = @rbhd[2]

        puts "yaml: lbhd (#{y_x1.to_s}, #{y_y1.to_s}, #{y_z1.to_s})  rbhd (#{y_x2.to_s}, #{y_y2.to_s}, #{y_z2.to_s})"
        puts ""
        puts "lbhd (#{x1.to_s}, #{y1.to_s}, #{z1.to_s})  rbhd (#{x2.to_s}, #{y2.to_s}, #{z2.to_s})"

        exit

        @rfhd[0]  = @lfhd[0] - (@yaml.lfhd.xtran.abs - @yaml.rfhd.xtran.abs)
        @rfhd[1]  = @lfhd[1]
        @rfhd[2]  = @lfhd[2]

        @rbhd[0]  = @lbhd[0] - (@yaml.lbhd.xtran.abs - @yaml.rbhd.xtran.abs)
        @rbhd[1]  = @lbhd[1]
        @rbhd[2]  = @lbhd[2]

        @good_distance = done?
        next
      end

      if( @good_distance[1] )  # rfhd <-> rbhd is ok
        @logger.message( :debug, "Distance rfhd<->rbhd is ok, using this as a basis" )

        difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) )

        # Use:
        # rfhd, rbhd, lfhd
        #
        # Repair:
        # lbhd

        # broken
        # "lf_lb"=>72.41031122742238
        # "lb_rb"=>74.02514167751507
        # "lb_rf"=>74.92686465035351
        
        # Good
        # "rf_rb"=>-0.0020435664357618677
        # "lf_rf"=>0.03235266882107446
        # "lf_rb"=>-0.12350072079968832

        # We trust the rbhd marker position
        raise ArgumentError, "Only ok to use this if rf_rb ok" unless( difference[ "rf_rb" ].abs < 5 )

        dx = @yaml.rbhd.xtran - @yaml.lbhd.xtran
        dy = @yaml.rbhd.ytran - @yaml.lbhd.ytran
        dz = @yaml.rbhd.ztran - @yaml.lbhd.ztran

        @lbhd[0] = @rbhd[0] + dx
        @lbhd[1] = @rbhd[1] + dy
        @lbhd[2] = @rbhd[2] + dz

        @good_distance = done?
        next
      end

      if( @good_distance[2] )  # lfhd <-> rfhd is ok
        @logger.message( :debug, "Distance lfhd<->rfhd is ok, using this as a basis" )

        difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) )
        p difference

        # Broken
        # "lf_lb"=>71.635095903395
        # "rf_rb"=>75.21619749032409
        # "lf_rb"=>69.51935660236448
        # "lb_rf"=>74.23191658719088
        #
        # Good
        # "lf_rf"=>0.03570059277488902
        # "lb_rb"=>-4.683474578966022

        # Use
        # lfhd, rfhd, lbhd, 

        # We trust the rfhd marker
        raise ArgumentError, "Only ok to use if lf_rf ok" unless( difference[ "lf_rf" ].abs < 5 )

        ref = Hash.new

        %w[lfhd lbhd rbhd rfhd].each do |m|
          tmp = []
          tmp << eval( "@yaml.#{m.to_s}.xtran.abs - @#{m.to_s}[0].abs" )
          tmp << eval( "@yaml.#{m.to_s}.ytran.abs - @#{m.to_s}[1].abs" )
          tmp << eval( "@yaml.#{m.to_s}.ztran.abs - @#{m.to_s}[2].abs" )
          tmp = tmp.sum
          ref[ m.to_s ] = tmp
        end

        puts "ref"
        p ref

        dx = @yaml.rbhd.xtran - @yaml.rfhd.xtran
        dy = @yaml.rbhd.ytran - @yaml.rfhd.ytran
        dz = @yaml.rbhd.ztran - @yaml.rfhd.ztran

        @rbhd[0] = @rfhd[0] - dx
        @rbhd[1] = @rfhd[1] - dy
        @rbhd[2] = @rfhd[2] - dz


        difference = get_difference( get_lengths( @lfhd, @lbhd, @rfhd, @rbhd ) )
        p difference

        exit

        @good_distance = done?
        next
      end

      if( @good_distance[3] )  # lbhd <-> rbhd is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[4] )  # lfhd <-> rbhd is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[5] )  # lbhd <-> rfhd is ok
        raise NotImplementedError
        next
      end

    end # of while


    # Recalculate pt24
    @pt24[0] = ( @lfhd[0] + @lbhd[0] + @rfhd[0] + @rbhd[0] ) / 4
    @pt24[1] = ( @lfhd[1] + @lbhd[1] + @rfhd[1] + @rbhd[1] ) / 4
    @pt24[2] = ( @lfhd[2] + @lbhd[2] + @rfhd[2] + @rbhd[2] ) / 4

    [ @lfhd, @lbhd, @rfhd, @rbhd, @pt24 ]
  end # of def repair_head! lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold # }}}


  # @fn       def get_lengths lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil # {{{
  # @brief    Calculates the lengths of the marker distances by eucledian distance calculation.
  #
  # @param    [Array]         lfhd            Left-Front Marker on the head. Array has the shape, xtran, ytran, ztran, etc.
  # @param    [Array]         lbhd            Left-Back Marker on the head.
  # @param    [Array]         rfhd            Right-Front Marker on the head.
  # @param    [Array]         rbhd            Right-Back Marker on the head.
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM
  #           Plugin. Only the first three values of the array are considered.
  #
  #
  # TOP VIEW OF HEAD
  # ================
  #
  #   rbhd    lbhd
  #     x      x
  #
  #
  #     x      x
  #   rfhd    lfhd
  #
  def get_lengths lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil

    # Sanity check
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )

    raise ArgumentError, "lfhd must be of type Array" unless( lfhd.is_a?( Array ) )
    raise ArgumentError, "lbhd must be of type Array" unless( lbhd.is_a?( Array ) )
    raise ArgumentError, "rfhd must be of type Array" unless( rfhd.is_a?( Array ) )
    raise ArgumentError, "rbhd must be of type Array" unless( rbhd.is_a?( Array ) )

    # Main control flow
    result            = Hash.new

    result[ "lf_lb" ] = ( @helpers.eucledian_distance( lfhd[0,3], lbhd[0,3] ) ).abs # left temple
    result[ "rf_rb" ] = ( @helpers.eucledian_distance( rfhd[0,3], rbhd[0,3] ) ).abs # right temple
    result[ "lf_rf" ] = ( @helpers.eucledian_distance( lfhd[0,3], rfhd[0,3] ) ).abs # forehead
    result[ "lb_rb" ] = ( @helpers.eucledian_distance( lbhd[0,3], rbhd[0,3] ) ).abs # back of the head
    result[ "lf_rb" ] = ( @helpers.eucledian_distance( lfhd[0,3], rbhd[0,3] ) ).abs # diagonal left front -> right back
    result[ "lb_rf" ] = ( @helpers.eucledian_distance( lbhd[0,3], rfhd[0,3] ) ).abs # diagonal left back  -> right front

    result
  end # of def get_lengths lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil # }}}


  # @fn       def ostruct_to_array openstruct # {{{
  # @brief    Turns a provided ostruct of the shape MotionX::VPM into a array, where only the first
  #           three values are considered (xtran, ytran, ztran)
  #
  # @param    [OpenStruct]      openstruct        OpenStruct, containing the keys xtran, ytran, ztran. Rest gets ignored.
  #
  # @returns  [Array]                             Returns array of the form [xtran, ytran, ztran]
  def ostruct_to_array openstruct = nil

    # Sanity check
    raise ArgumentError, "openstruct cannot be nil" if( openstruct.nil? )
    raise ArgumentError, "openstruct needs to be of type OStruct" unless( openstruct.is_a?( OpenStruct ) )

    # Main flow
    result = []

    result << openstruct.xtran
    result << openstruct.ytran
    result << openstruct.ztran

    result
  end # of def ostruct_to_array openstruct = nil # }}}

end # of class Head }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100

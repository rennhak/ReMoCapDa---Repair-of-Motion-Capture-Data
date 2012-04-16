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

    # Go through markers and correct where incorrect 0..n
    @keys             = yaml.instance_variable_get("@table").keys


    reference         = [ @yaml.lfhd, @yaml.lbhd, @yaml.rfhd, @yaml.rbhd ]
    @yaml_frame_head  = get_lengths( *( reference.collect { |i| ostruct_to_array( i ) } ) )

    @frame_head       = nil

  end # of def initialize }}}


  # @fn       def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
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
  def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

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
  end # }}}


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


  # @fn       def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
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
  def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )
    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )


    @lfhd, @lbhd, @rfhd, @rbhd, @pt24 = lfhd, lbhd, rfhd, rbhd, pt24


    # find out which distance is ok
    @good_distance = []  # true == length is ok
    @diff.each { |n| @good_distance << ( n < threshhold ) ? ( false ) : ( true ) } 

    # Iterate over markers until repaired
    while( @good_distance.include?( false ) )

      @frame_head = []

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed" )

      # Length of current frame
      # length of 4 sides
      @frame_head << lf_lb_distance = @helpers.eucledian_distance( @lfhd[0,3], @lbhd[0,3] )
      @frame_head << rf_rb_distance = @helpers.eucledian_distance( @rfhd[0,3], @rbhd[0,3] )
      @frame_head << lf_rf_distance = @helpers.eucledian_distance( @lfhd[0,3], @rfhd[0,3] )
      @frame_head << lb_rb_distance = @helpers.eucledian_distance( @lbhd[0,3], @rbhd[0,3] )

      @frame_head << lf_rb_distance = @helpers.eucledian_distance( @lfhd[0,3], @rbhd[0,3] )
      @frame_head << lb_rf_distance = @helpers.eucledian_distance( @lbhd[0,3], @rfhd[0,3] )

      @diff        = @frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }

      # find out which distance is ok
      @good_distance = []
      @diff.each { |n| @good_distance << ( n < threshhold ) ? ( false ) : ( true ) } 

      break unless( @good_distance.include?( false ) )

      if( @good_distance[0] )  # lfhd <-> lbhd is ok

        @rfhd[0]  = @lfhd[0] - (@yaml.lfhd.xtran.abs - @yaml.rfhd.xtran.abs)
        @rfhd[1]  = @lfhd[1]
        @rfhd[2]  = @lfhd[2]

        @rbhd[0]  = @lbhd[0] - (@yaml.lbhd.xtran.abs - @yaml.rbhd.xtran.abs)
        @rbhd[1]  = @lbhd[1]
        @rbhd[2]  = @lbhd[2]

        next
      end

      if( @good_distance[1] )  # rfhd <-> rbhd is ok
        @logger.message( :debug, "Distance rfhd<->rbhd is ok, using this as a basis" )

        # FIXME: Calculate angle between lines

        # TOP VIEW

        # lfhd   rfhd
        #   o     o
        #
        #      o pt24
        #   o     o
        # lbhd   rbhd

        @lfhd[0]  = @rfhd[0] - (@yaml.rfhd.xtran.abs - @yaml.lfhd.xtran.abs)
        @lfhd[1]  = @rfhd[1]
        @lfhd[2]  = @rfhd[2]

        @lbhd[0]  = @rbhd[0] - (@yaml.rbhd.xtran.abs - @yaml.lbhd.xtran.abs)
        @lbhd[1]  = @rbhd[1]
        @lbhd[2]  = @rbhd[2]

        # This is a naive method
        #@lfhd[0]  = @yaml.lfhd.xtran
        #@lfhd[1]  = @yaml.lfhd.ytran
        #@lfhd[2]  = @yaml.lfhd.ztran

        #@lbhd[0]  = @yaml.lbhd.xtran
        #@lbhd[1]  = @yaml.lbhd.ytran
        #@lbhd[2]  = @yaml.lbhd.ztran

        next
      end

      if( @good_distance[2] )  # lfhd <-> rfhd is ok
        @logger.message( :debug, "Distance lfhd<->rfhd is ok, using this as a basis" )

        @lbhd[0]  = @lfhd[0]
        #@lbhd[1]  = @lfhd[1]
        #@lbhd[2]  = @lfhd[2] - (@yaml.lfhd.ztran.abs - @yaml.lbhd.ztran.abs)

        @rbhd[0]  = @rfhd[0]
        #@rbhd[1]  = @rfhd[1]
        #@rbhd[2]  = @rfhd[2] - (@yaml.rfhd.ztran.abs - @yaml.rbhd.ztran.abs)

        # This is a naive method
        # @lbhd[0]  = @yaml.lbhd.xtran
        @lbhd[1]  = @yaml.lbhd.ytran
        @lbhd[2]  = @yaml.lbhd.ztran

        # @rbhd[0]  = @yaml.rbhd.xtran
        @rbhd[1]  = @yaml.rbhd.ytran
        @rbhd[2]  = @yaml.rbhd.ztran

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
  end # }}}



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

    result[ "lf_lb" ] = @helpers.eucledian_distance( lfhd[0,3], lbhd[0,3] ) # left temple
    result[ "rf_rb" ] = @helpers.eucledian_distance( rfhd[0,3], rbhd[0,3] ) # right temple
    result[ "lf_rf" ] = @helpers.eucledian_distance( lfhd[0,3], rfhd[0,3] ) # forehead
    result[ "lb_rb" ] = @helpers.eucledian_distance( lbhd[0,3], rbhd[0,3] ) # back of the head
    result[ "lf_rb" ] = @helpers.eucledian_distance( lfhd[0,3], rbhd[0,3] ) # diagonal left front -> right back
    result[ "lb_rf" ] = @helpers.eucledian_distance( lbhd[0,3], rfhd[0,3] ) # diagonal left back  -> right front

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

#!/usr/bin/ruby
#

###
#
# File: Hands.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Hands.rb
# @author     Bjoern Rennhak
#
#######


# Libaries
$:.push('..')
require 'Helpers.rb'
require 'Mathematics.rb'


# @class      class Hands # {{{
# @brief      The class Hands takes motion capture data and checks if some markers are broken. If so it tries to repair it.
class Hands

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Hands class
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
    @mathematics      = Mathematics.new

    @logger.message :debug, "Using threshhold (#{threshhold.to_s})"

    # Go through markers and correct where incorrect 0..n
    @keys             = yaml.instance_variable_get("@table").keys
    @order            = [ "rfin_rwra", "rfin_rwrb", "rwra_rwrb", "lfin_lwra", "lfin_lwrb", "lwra_lwrb" ]

    reference         = [ @yaml.rfin, @yaml.rwra, @yaml.rwrb, @yaml.lfin, @yaml.lwra, @yaml.lwrb ]

    @yaml_frame_hands = get_lengths( *( reference.collect { |i| ostruct_to_array( i ) } ) )

    @frame_hands      = nil

    @rfin             = nil
    @rwra             = nil
    @rwrb             = nil
    @lfin             = nil
    @lwra             = nil
    @lwrb             = nil

    # We need the elbows as well
    @lelb             = nil
    @relb             = nil

    @repair_frames    = nil

  end # of def initialize }}}


  # @fn       def repair_hands? rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, threshhold = @threshhold # {{{
  # @brief    Checks if the hands markers need repairing
  #
  # @param    [Array]         rwra            Array for the rwra marker
  # @param    [Array]         rwrb            Array for the rwrb marker
  # @param    [Array]         lwra            Array for the lwra marker
  # @param    [Array]         lwrb            Array for the lwrb marker
  # @param    [Array]         lfin            Array for the lfin marker
  # @param    [Array]         rfin            Array for the rfin marker
  # @param    [Fixnum]        threshhold      Threshhold is the value we accept as being still ok deviating from the T-Pose measurement (e.g. <10)
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def repair_hands? rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, threshhold = @threshhold

    # Sanity check
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )

    raise ArgumentError, "rfin can't be nil" unless( rfin.is_a?( Array ) )
    raise ArgumentError, "rwra can't be nil" unless( rwra.is_a?( Array ) )
    raise ArgumentError, "rwrb can't be nil" unless( rwrb.is_a?( Array ) )
    raise ArgumentError, "lfin can't be nil" unless( lfin.is_a?( Array ) )
    raise ArgumentError, "lwra can't be nil" unless( lwra.is_a?( Array ) )
    raise ArgumentError, "lwrb can't be nil" unless( lwrb.is_a?( Array ) )

    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )

    # Main control flow
    result              = false

    # get lengths of current frame for the hands
    @frame_hands        = get_lengths( rfin, rwra, rwrb, lfin, lwra, lwrb )
    difference          = get_difference( @frame_hands )

    result = true if( difference[ "sum" ] > threshhold )

    @logger.message :debug, "RFIN (#{@rfin[0,3].join(",")}), RWRA (#{@rwra[0,3].join(",")}), RWRB (#{@rwrb[0,3].join(",")}) - LFIN (#{@lfin[0,3].join(",")}) LWRA (#{@lwra[0,3].join(",")}) LWRB (#{@lwrb[0,3].join(",")})"
    @logger.message :debug, "RELB (#{@relb[0,3].join(",")}), LELB (#{@lelb[0,3].join(",")})"

    result
  end # of def repair_hands? rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, threshhold = @threshhold # }}}


  # @fn       def get_difference frame = nil, reference_frame = @yaml_frame_hands # {{{
  # @brief    Get difference takes the reference frame (t-pose) and the current frame and calculates
  #           the difference array for each corresponding markers as well as the sum of it for threshholding.
  #
  # @param    [Hash]        reference_frame     Reference frame is a hash containing all relevant hands markers (from yaml)
  # @param    [Hash]        frame               Frame is a hash containing all relevant hands markers (current frame) 
  #
  # @returns                                    The get_difference function returns a hash containing the difference of 
  #                                             each marker pair was well as the sum of differences stored by the
  #                                             "sum" key.
  def get_difference frame = nil, reference_frame = @yaml_frame_hands
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


  # @fn       def set_markers rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb # {{{
  # @brief    Sets markers inside the class state
  #
  # @param    [Array]         rwra            Array for the rwra marker
  # @param    [Array]         rwrb            Array for the rwrb marker
  # @param    [Array]         lwra            Array for the lwra marker
  # @param    [Array]         lwrb            Array for the lwrb marker
  # @param    [Array]         lfin            Array for the lfin marker
  # @param    [Array]         rfin            Array for the rfin marker
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def set_markers rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, lelb = @lelb, relb = @relb
    @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb, @lelb, @relb  = rfin, rwra, rwrb, lfin, lwra, lwrb, lelb, relb
  end # of def set_markers rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb # }}}


  # @fn       def done? difference = get_difference( get_lengths( @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb ) ), threshhold = @threshhold, order = @order # {{{
  # @brief    Done takes the difference from the current to the reference coordinates (local) and if bigger than threshhold returns an array for each @order pair
  #
  # @param    [Hash]      difference        Output from the get_difference function
  # @param    [Fixnum]    threshhold        Threshhold provided at the instantiation of the class
  # @param    [Array]     order             Order of the pairs we evalutate
  #
  # @returns  [Array]                       Array, containing booleans in der order of the @order array
  def done? difference = get_difference( get_lengths( @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb ) ), threshhold = @threshhold, order = @order

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
  end # of def done? difference = get_difference( get_lengths( @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb ) ), threshhold = @threshhold, order = @order # }}}


  # @fn       def repair_hands! rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, threshhold = @threshhold # {{{
  # @brief    Repairs hands markers
  #
  # @param    [Array]         rwra            Array for the rwra marker
  # @param    [Array]         rwrb            Array for the rwrb marker
  # @param    [Array]         lwra            Array for the lwra marker
  # @param    [Array]         lwrb            Array for the lwrb marker
  # @param    [Array]         lfin            Array for the lfin marker
  # @param    [Array]         rfin            Array for the rfin marker
  # @param    [Fixnum]        threshhold      Threshhold is the value we accept as being still ok deviating from the T-Pose measurement (e.g. <10)
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM Plugin.
  def repair_hands! rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )

    raise ArgumentError, "rfin can't be nil" unless( rfin.is_a?( Array ) )
    raise ArgumentError, "rwra can't be nil" unless( rwra.is_a?( Array ) )
    raise ArgumentError, "rwrb can't be nil" unless( rwrb.is_a?( Array ) )
    raise ArgumentError, "lfin can't be nil" unless( lfin.is_a?( Array ) )
    raise ArgumentError, "lwra can't be nil" unless( lwra.is_a?( Array ) )
    raise ArgumentError, "lwrb can't be nil" unless( lwrb.is_a?( Array ) )

    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )

    # check repair frames (before, self, after)
    b_index, b_data     = [], []
    s_index, s_data     = [], []
    a_index, a_data     = [], []

    @frames[0].each { |array| b_index << array.first ; b_data << array.last }
    @frames[1].each { |array| s_index << array.first ; s_data << array.last }
    @frames[2].each { |array| a_index << array.first ; a_data << array.last }

    large_distance      = false

    @logger.message( :debug, "Before frames are fine, we have two valid ones (#{b_index.join(" ")})" ) if( b_index.length >= 2 )
    @logger.message( :warning, "Before frames are thin, we have ONLY one valid one (#{b_index.join(" ")})" ) if( b_index.length == 1 )
    @logger.message( :error, "We have no before frames, that means we cannot interpolate to repair" ) if( b_index.length == 0 )

    if( b_index.length > 0 )
      b_diff              = 0
      b_index.each { |x| b_diff += (x - s_index.first).abs } 
      b_diff /= b_index.length

      @logger.message( :error, "Seems the distance between self index (#{s_index.join(" ")}) and before (#{b_index.join(" ")}) is too large" ) if( b_diff > 10 )
      large_distance      = true
    end

    raise ArgumentError, "There was some problem with the @frames, we don't have the self frame?!" unless( s_index.length == 1 )

    @logger.message( :debug, "After frames are fine, we have two valid ones (#{a_index.join(" ")})" ) if( a_index.length >= 2 )
    @logger.message( :warning, "After frames are thin, we have ONLY one valid one (#{a_index.join(" ")})" ) if( a_index.length == 1 )
    @logger.message( :error, "We have no after frames, that means we cannot interpolate to repair" ) if( a_index.length == 0 )

    if( a_index.length > 0 )
      a_diff              = 0
      a_index.each { |x| a_diff += ( x - s_index.first ).abs }
      a_diff /= a_index.length

      @logger.message( :error, "Seems the distance between self index (#{s_index.join(" ")}) and after (#{a_index.join(" ")}) is too large" ) if( a_diff > 10 )
      large_distance      = true
    end

    exit

    # Iterate over markers until repaired
    @good_distance = done?

    while( @good_distance.include?( false ) )

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed (#{@good_distance.join( ", " )})" )
 
      difference = get_difference( get_lengths( @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb ) )

      unless( @good_distance[0] ) # rfin_rwra => damaged
        raise NotImplementedError

        @good_distance = done?
        next
      end

      unless( @good_distance[1] ) # rfin_rwrb
        raise NotImplementedError

        @good_distance = done?
        next
      end

      unless( @good_distance[2] ) # rwra_rwrb
        raise NotImplementedError

        @good_distance = done?
        next
      end

      unless( @good_distance[3] ) # lfin_lwra
        raise NotImplementedError

        @good_distance = done?
        next
      end

      unless( @good_distance[4] ) # lfin_lwrb

        p "--"
        p before_frames
        p "--"
        p self_frame
        p "--"
        p after_frames
        p "--"

        raise NotImplementedError
        # Guard
        raise ArgumentError, "Distance lfin_lwra is damaged as well, how to repair?" unless( @good_distance[3] )

        # TODO: Check lelb is ok

        # Took the inspiration from
        # http://board.flashkit.com/board/showthread.php?t=814954

        # We use the triangle lfin_lwrb_lwra, where we know that lfin and lwra are ok
        #
        #            o  lfin
        #           / \
        #          /   \
        # C lwrb  o-----o  B lwra
        #         \     /
        #          \   /
        #           \ /
        #            o
        #         A lelb
        #
        # We know the distances

        # a = @lelb[0,3]
        # b = @lwra[0,3]

        # u = [ b[0]-a[0], b[1]-a[1], b[2]-a[2] ]

        # dangle_yx = Math.atan2( u[1], u[0] ) - Math::PI / 3   # // z axis from x, y/x forms z angle 
        # dangle_zx = Math.atan2( u[2], u[0] ) - Math::PI / 3   # // y axis from x, z/x forms y angle 
        # dangle_zy = Math.atan2( u[2], u[1] ) - Math::PI / 3   # // x axis from y, z/y forms x angle 

        # dist_yx   = Math.sqrt( u[1]*u[1] + u[0]*u[0] )
        # dist_zx   = Math.sqrt( u[2]*u[2] + u[0]*u[0] )
        # dist_zy   = Math.sqrt( u[2]*u[2] + u[1]*u[1] )

        # yx = []
        # yx << Math.cos( dangle_yx ) * dist_yx + a[0]
        # yx << Math.sin( dangle_yx ) * dist_yx + a[1]

        # zx = []
        # zx << Math.cos( dangle_zx ) * dist_zx + a[2]
        # zx << Math.sin( dangle_zx ) * dist_zx + a[0]

        # zy = []
        # zy << Math.cos( dangle_zy ) * dist_zy + a[2]
        # zy << Math.sin( dangle_zy ) * dist_zy + a[1]

        # @lwrb[0] = yx[0]
        # @lwrb[1] = zx[0]
        # @lwrb[2] = zy[0]

        # @logger.message :debug, "@lwrb -> #{@lwrb[0,3].join(',')}"
        # @logger.message :debug, "yaml lwrb -> #{ostruct_to_array( @yaml.lwrb ).join(',')}"
        # p yx
        # p zx
        # p zy

        # p difference
        # STDIN.gets

        # exit

        @good_distance = done?
        next
      end

      unless( @good_distance[5] ) # lwra_lwrb
        raise NotImplementedError

        @good_distance = done?
        next
      end

#      if( @good_distance[0] )  # rfin <-> rwra is ok
#
#        # Guard
#        raise ArgumentError, "RFIN <-> RWRA must be below thresshold" if( difference[ "rfin_rwra" ] > @threshhold )
#
#        
#
#        y_relb = ostruct_to_array( @yaml.relb )
#        y_lelb = ostruct_to_array( @yaml.lelb )
#
#        p y_relb
#        p @relb[0,3]
#        p "--"
#
#        p y_lelb
#        p @lelb[0,3]
#
#        exit
#        next
#      end
#
#      if( @good_distance[1] )  # rfin <-> rwrb is ok
#
#       raise NotImplementedError
#
#        @logger.message( :warning," ---> Repair" )
#        @rwra[0]  = @rwrb[0] - (@yaml.rwrb.xtran.abs - @yaml.rwra.xtran.abs)
#        @rwra[1]  = @rwrb[1]
#        @rwra[2]  = @rwrb[2]
#
#        @good_distance = done?
#        next
#      end
#
#      if( @good_distance[2] )  # lfin <-> lwra is ok
#        raise NotImplementedError
#        next
#      end
# 
#      if( @good_distance[3] )  # lfin <-> lwrb is ok
#        raise NotImplementedError
#        next
#      end
#
#      if( @good_distance[4] )  # rwra <-> rwrb is ok
#        raise NotImplementedError
#        next
#      end
#
#      if( @good_distance[5] )  # lwra lwrb is ok
#        raise NotImplementedError
#        next
#      end
#
    end # of while

    [ @rwra, @rwrb, @lwra, @lwrb, @lfin, @rfin ]

  end # of def repair_hands! lfhd = @lfhd, lbhd = @lbhd, rfhd = @rfhd, rbhd = @rbhd, pt24 = @pt24, threshhold = @threshhold # }}}


  # @fn       def get_lengths rfin = nil, rwra = nil, rwrb = nil, lfin = nil, lwra = nil, lwrb = nil # {{{
  # @brief    Calculates the lengths of the marker distances by eucledian distance calculation.
  #
  # @param    [Array]         rwra        Array for the rwra marker
  # @param    [Array]         rwrb        Array for the rwrb marker
  # @param    [Array]         lwra        Array for the lwra marker
  # @param    [Array]         lwrb        Array for the lwrb marker
  # @param    [Array]         lfin        Array for the lfin marker
  # @param    [Array]         rfin        Array for the rfin marker
  #
  # @note     All marker arrays are in the shape of the VPM data provided by the MptionX::VPM
  #           Plugin. Only the first three values of the array are considered.
  def get_lengths rfin = nil, rwra = nil, rwrb = nil, lfin = nil, lwra = nil, lwrb = nil

    # Sanity check
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )

    raise ArgumentError, "rfin can't be nil" unless( rfin.is_a?( Array ) )
    raise ArgumentError, "rwra can't be nil" unless( rwra.is_a?( Array ) )
    raise ArgumentError, "rwrb can't be nil" unless( rwrb.is_a?( Array ) )
    raise ArgumentError, "lfin can't be nil" unless( lfin.is_a?( Array ) )
    raise ArgumentError, "lwra can't be nil" unless( lwra.is_a?( Array ) )
    raise ArgumentError, "lwrb can't be nil" unless( lwrb.is_a?( Array ) )

    # Main control flow
    result            = Hash.new

    result[ "rfin_rwra" ] = ( @helpers.eucledian_distance( rfin[0,3], rwra[0,3] ) ).abs # fingers
    result[ "rfin_rwrb" ] = ( @helpers.eucledian_distance( rfin[0,3], rwrb[0,3] ) ).abs # fingers
    result[ "lfin_lwra" ] = ( @helpers.eucledian_distance( lfin[0,3], lwra[0,3] ) ).abs # fingers
    result[ "lfin_lwrb" ] = ( @helpers.eucledian_distance( lfin[0,3], lwrb[0,3] ) ).abs # fingers
    result[ "rwra_rwrb" ] = ( @helpers.eucledian_distance( rwra[0,3], rwrb[0,3] ) ).abs # wrist
    result[ "lwra_lwrb" ] = ( @helpers.eucledian_distance( lwra[0,3], lwrb[0,3] ) ).abs # wrist

    result
  end # of def get_lengths rfin = nil, rwra = nil, rwrb = nil, lfin = nil, lwra = nil, lwrb = nil # }}}


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

end # of class Hands }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100

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

    # Go through markers and correct where incorrect 0..n
    @keys             = yaml.instance_variable_get("@table").keys
    @order            = [ "rfin_rwra", "rfin_rwrb", "lfin_lwra", "lfin_lwrb", "rwra_rwrb", "lwra_lwrb" ]

    reference         = [ @yaml.rfin, @yaml.rwra, @yaml.rwrb, @yaml.lfin, @yaml.lwra, @yaml.lwrb ]

    @yaml_frame_hands  = get_lengths( *( reference.collect { |i| ostruct_to_array( i ) } ) )

    @frame_hands       = nil

    @rfin             = nil
    @rwra             = nil
    @rwrb             = nil
    @lfin             = nil
    @lwra             = nil
    @lwrb             = nil

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
  def set_markers rfin = @rfin, rwra = @rwra, rwrb = @rwrb, lfin = @lfin, lwra = @lwra, lwrb = @lwrb
    @rfin, @rwra, @rwrb, @lfin, @lwra, @lwrb  = rfin, rwra, rwrb, lfin, lwra, lwrb
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


    # Iterate over markers until repaired
    @good_distance = done?
    while( @good_distance.include?( false ) )

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed (#{@good_distance.join( ", " )})" )

      if( @good_distance[0] )  # rfin <-> rwra is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[1] )  # rfin <-> rwrb is ok
        @logger.message( :warning," ---> Repair" )
        @rwra[0]  = @rwrb[0] - (@yaml.rwrb.xtran.abs - @yaml.rwra.xtran.abs)
        @rwra[1]  = @rwrb[1]
        @rwra[2]  = @rwrb[2]

        @good_distance = done?
        next
      end

      if( @good_distance[2] )  # lfin <-> lwra is ok
        raise NotImplementedError
        next
      end
 
      if( @good_distance[3] )  # lfin <-> lwrb is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[4] )  # rwra <-> rwrb is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[5] )  # lwra lwrb is ok
        raise NotImplementedError
        next
      end

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

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


$:.push('.')


# @class      class Repair # {{{
# @brief      The class Repair takes motion capture data and checks if some markers are broken. If so it tries to repair it.
class Repair

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Repair class
  def initialize logger = nil, yaml = nil, threshhold = nil

    # Sanity check
    raise ArgumentError, "Logger can't be nil" if( logger.nil? )
    raise ArgumentError, "Yaml can't be nil" if( yaml.nil? )
    raise ArgumentError, "Threshhold can't be nil" if( threshhold.nil? )

    @logger       = logger
    @yaml         = yaml
    @threshhold   = threshhold

    # Go through markers and correct where incorrect 0..n
    @keys         = yaml.instance_variable_get("@table").keys

  end # of def initialize }}}


  # @fn       def run
  # @brief    Run checks the motion data for problems and tries to repair it
  def run motion_capture_data
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
      data = hashes_to_ostruct( data )

      @logger.message( :debug, "[ Frame: #{frame_index.to_s} ]" )
      @logger.message( :debug, "\tChecking if head needs repair" )
      # Do checking and repair
      if( repair_head?( data.lfhd, data.lbhd, data.rfhd, data.rbhd, data.pt24 ) )
        @logger.message( :warning, "Repairing head at frame (#{frame_index.to_s})" )

        lfhd, lbhd, rfhd, rbhd, pt24 = repair_head!( data.lfhd, data.lbhd, data.rfhd, data.rbhd, data.pt24 )

        %w[lfhd lbhd rfhd rbhd pt24].each do |marker|
          eval( "motion_capture_data.#{marker.to_s}.xtran[ #{frame_index.to_i} ] = #{marker.to_s}[0]" )
          eval( "motion_capture_data.#{marker.to_s}.ytran[ #{frame_index.to_i} ] = #{marker.to_s}[1]" )
          eval( "motion_capture_data.#{marker.to_s}.ztran[ #{frame_index.to_i} ] = #{marker.to_s}[2]" )
        end
      end # of repair_head

      @logger.message( :debug, "\tChecking if hand needs repair" )

      if( repair_hand?( data.rwra, data.rwrb, data.lwra, data.lwrb, data.lfin, data.rfin, 2 ) )
        @logger.message( :warning, "Repairing hand at frame (#{frame_index.to_s})" )

        rwra, rwrb, lwra, lwrb, lfin, rfin = repair_hand!( data.rwra, data.rwrb, data.lwra, data.lwra, data.lfin, data.rfin )

        %w[rwra rwrb lwra lwrb lfin rfin].each do |marker|
          eval( "motion_capture_data.#{marker.to_s}.xtran[ #{frame_index.to_i} ] = #{marker.to_s}[0]" )
          eval( "motion_capture_data.#{marker.to_s}.ytran[ #{frame_index.to_i} ] = #{marker.to_s}[1]" )
          eval( "motion_capture_data.#{marker.to_s}.ztran[ #{frame_index.to_i} ] = #{marker.to_s}[2]" )
        end

      end # of repair_hand


    end # of 0.upto( frames - 1 )

    # Return result
    result
  end # of def run # }}}


  # @fn       def repair_hand?  # {{{
  # @brief    Checks if the hand markers need repairing
  def repair_hand? rwra = nil, rwrb = nil, lwra = nil, lwrb = nil, lfin = nil, rfin = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )

    result = false
    frame_hand = []
    yaml_frame_hand = []


    # Fingers
    frame_hand << rfin_rwra_distance = eucledian_distance( rfin[0,3], rwra[0,3] )
    frame_hand << rfin_rwrb_distance = eucledian_distance( rfin[0,3], rwrb[0,3] )

    frame_hand << lfin_lwra_distance = eucledian_distance( lfin[0,3], lwra[0,3] )
    frame_hand << lfin_lwrb_distance = eucledian_distance( lfin[0,3], lwrb[0,3] )

    # Wrist
    frame_hand << rwra_rwrb_distance = eucledian_distance( rwra[0,3], rwra[0,3] )
    frame_hand << lwra_lwrb_distance = eucledian_distance( lwrb[0,3], lwrb[0,3] )

    
    # Fingers
    yaml_frame_hand << yaml_rfi_lb_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )

    # Fingers
    yaml_frame_hand << yaml_rfin_rwra_distance = eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_rfin_rwrb_distance = eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwrb ) )

    yaml_frame_hand << yaml_lfin_lwra_distance = eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwra ) )
    yaml_frame_hand << yaml_lfin_lwrb_distance = eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwrb ) )

    # Wrist
    yaml_frame_hand << yaml_rwra_rwrb_distance = eucledian_distance( get_array( @yaml.rwra), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_lwra_lwrb_distance = eucledian_distance( get_array( @yaml.lwrb), get_array( @yaml.lwrb ) )

    diff        = frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }
    diff_sum    = diff.sum

    if( diff_sum > threshhold )
      result = true 

      # puts "--- Diff_sum (#{diff_sum.to_s}) -> Threshhold (#{threshhold.to_s})"
    end

    result
  end # }}}



  # @fn       def repair_hand!  # {{{
  # @brief    Repairs hand markers
  def repair_hand! rwra = nil, rwrb = nil, lwra = nil, lwrb = nil, lfin = nil, rfin = nil, threshhold = @threshhold
    @logger.message( :warning, "Reparing hand" )

    @rwra, @rwrb, @lwra, @lwrb, @lfin, @rfin = rwra, rwrb, lwra, lwrb, lfin, rfin

    # check sanity
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )

    result = false
    @frame_hand = []
    yaml_frame_hand = []


    # Fingers
    @frame_hand << rfin_rwra_distance = eucledian_distance( @rfin[0,3], @rwra[0,3] )
    @frame_hand << rfin_rwrb_distance = eucledian_distance( @rfin[0,3], @rwrb[0,3] )

    @frame_hand << lfin_lwra_distance = eucledian_distance( @lfin[0,3], @lwra[0,3] )
    @frame_hand << lfin_lwrb_distance = eucledian_distance( @lfin[0,3], @lwrb[0,3] )

    # Wrist
    @frame_hand << rwra_rwrb_distance = eucledian_distance( @rwra[0,3], @rwra[0,3] )
    @frame_hand << lwra_lwrb_distance = eucledian_distance( @lwrb[0,3], @lwrb[0,3] )

    # Fingers
    yaml_frame_hand << yaml_rfin_rwra_distance = eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_rfin_rwrb_distance = eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwrb ) )

    yaml_frame_hand << yaml_lfin_lwra_distance = eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwra ) )
    yaml_frame_hand << yaml_lfin_lwrb_distance = eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwrb ) )

    # Wrist
    yaml_frame_hand << yaml_rwra_rwrb_distance = eucledian_distance( get_array( @yaml.rwra), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_lwra_lwrb_distance = eucledian_distance( get_array( @yaml.lwrb), get_array( @yaml.lwrb ) )

    @diff        = @frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }

    # find out which distance is ok
    @good_distance = []  # true == length is ok
    @diff.each do |n| 
      p n
      @good_distance << ( n < threshhold ) ? ( true ) : ( false ) 
      p @good_distance
      STDIN.gets
    end

    # Iterate over markers until repaired
    while( @good_distance.include?( false ) )

      @frame_hand = []

      @logger.message( :debug, "Iterating over good distance check for hand frame until it is fixed" )

      # Fingers
      @frame_hand << rfin_rwra_distance = eucledian_distance( @rfin[0,3], @rwra[0,3] )
      @frame_hand << rfin_rwrb_distance = eucledian_distance( @rfin[0,3], @rwrb[0,3] )

      @frame_hand << lfin_lwra_distance = eucledian_distance( @lfin[0,3], @lwra[0,3] )
      @frame_hand << lfin_lwrb_distance = eucledian_distance( @lfin[0,3], @lwrb[0,3] )

      # Wrist
      @frame_hand << rwra_rwrb_distance = eucledian_distance( @rwra[0,3], @rwra[0,3] )
      @frame_hand << lwra_lwrb_distance = eucledian_distance( @lwrb[0,3], @lwrb[0,3] )


      @diff        = @frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }

      # find out which distance is ok
      @good_distance = []
      @diff.each { |n| @good_distance << ( n > threshhold ) ? ( false ) : ( true ) } 

      break unless( @good_distance.include?( false ) )

      if( @good_distance[0] )  # rfin <-> rwra is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[1] )  # rfin <-> rwrb is ok
        @logger.message( :warning," ---> Repair" )
        @rwra[0]  = @rwrb[0] - (@yaml.rwrb.xtran.abs - @yaml.rwra.xtran.abs)
        @rwra[1]  = @rwrb[1]
        @rwra[2]  = @rwrb[2]

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
  end # }}}



  # @fn       def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
  # @brief    Checks if the head markers need repairing
  def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )

    result = false
    frame_head = []
    yaml_frame_head = []


    # Length of current frame
    # length of 4 sides
    frame_head << lf_lb_distance = eucledian_distance( lfhd[0,3], lbhd[0,3] )
    frame_head << rf_rb_distance = eucledian_distance( rfhd[0,3], rbhd[0,3] )
    frame_head << lf_rf_distance = eucledian_distance( lfhd[0,3], rfhd[0,3] )
    frame_head << lb_rb_distance = eucledian_distance( lbhd[0,3], rbhd[0,3] )

    # length of cross
    frame_head << lf_rb_distance = eucledian_distance( lfhd[0,3], rbhd[0,3] )
    frame_head << lb_rf_distance = eucledian_distance( lbhd[0,3], rfhd[0,3] )

    # Length of reference frame
    yaml_frame_head << yaml_lf_lb_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )
    yaml_frame_head << yaml_rf_rb_distance = eucledian_distance( get_array( @yaml.rfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lf_rf_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rfhd ) )
    yaml_frame_head << yaml_lb_rb_distance = eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rbhd ) )

    # length of cross
    yaml_frame_head << yaml_lf_rb_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lb_rf_distance = eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rfhd ) )

    diff        = frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }
    diff_sum    = diff.sum

    result = true if( diff_sum > threshhold )
    #if( result ) 
    #  p diff
    #  p diff_sum
    #end

    result
  end # }}}


  def get_array openstruct
    result = []

    result << openstruct.xtran
    result << openstruct.ytran
    result << openstruct.ztran

    result
  end


  # @fn       def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
  # @brief    Repairs head markers
  def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )

    @frame_head = []
    yaml_frame_head = []

    @lfhd, @lbhd, @rfhd, @rbhd, @pt24 = lfhd, lbhd, rfhd, rbhd, pt24

    # Length of reference frame
    yaml_frame_head << yaml_lf_lb_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )
    yaml_frame_head << yaml_rf_rb_distance = eucledian_distance( get_array( @yaml.rfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lf_rf_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rfhd ) )
    yaml_frame_head << yaml_lb_rb_distance = eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rbhd ) )

    # length of cross
    yaml_frame_head << yaml_lf_rb_distance = eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lb_rf_distance = eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rfhd ) )

    # Length of current frame
    # length of 4 sides
    @frame_head << lf_lb_distance = eucledian_distance( @lfhd[0,3], @lbhd[0,3] )
    @frame_head << rf_rb_distance = eucledian_distance( @rfhd[0,3], @rbhd[0,3] )
    @frame_head << lf_rf_distance = eucledian_distance( @lfhd[0,3], @rfhd[0,3] )
    @frame_head << lb_rb_distance = eucledian_distance( @lbhd[0,3], @rbhd[0,3] )

    # length of cross
    @frame_head << lf_rb_distance = eucledian_distance( @lfhd[0,3], @rbhd[0,3] )
    @frame_head << lb_rf_distance = eucledian_distance( @lbhd[0,3], @rfhd[0,3] )

    @diff        = @frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }

    # find out which distance is ok
    @good_distance = []  # true == length is ok
    @diff.each { |n| @good_distance << ( n < threshhold ) ? ( false ) : ( true ) } 

    # Iterate over markers until repaired
    while( @good_distance.include?( false ) )

      @frame_head = []

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed" )

      # Length of current frame
      # length of 4 sides
      @frame_head << lf_lb_distance = eucledian_distance( @lfhd[0,3], @lbhd[0,3] )
      @frame_head << rf_rb_distance = eucledian_distance( @rfhd[0,3], @rbhd[0,3] )
      @frame_head << lf_rf_distance = eucledian_distance( @lfhd[0,3], @rfhd[0,3] )
      @frame_head << lb_rb_distance = eucledian_distance( @lbhd[0,3], @rbhd[0,3] )

      @frame_head << lf_rb_distance = eucledian_distance( @lfhd[0,3], @rbhd[0,3] )
      @frame_head << lb_rf_distance = eucledian_distance( @lbhd[0,3], @rfhd[0,3] )

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


  # @fn       def eucledian_distance point1, point2 # {{{
  # @brief    The eucledian_distance function takes two points in R^3 (x,y,z) and calculates the distance between them.
  #           You can easily derive this function via Pythagoras formula. P1,P2 \elem R^3
  #
  #           d(P1, P2) = \sqrt{ (x_2 - x_1)^2 + (y_2 - y_1)^2 + (z_2 - z_1)^2 }
  #
  #           Further reading:
  #           http://en.wikipedia.org/wiki/Distance
  #           http://en.wikipedia.org/wiki/Euclidean_distance
  #
  # @param    [Array]   point1  Accepts array containing floats or integers (x,y,z)
  # @param    [Array]   point2  Accepts array containing floats or integers (x,y,z)
  #
  # @returns  [Float]   Float, the distance between point 1 and point 2
  def eucledian_distance point1 = nil, point2 = nil

    # Pre-condition check {{{
    raise Error, "Points can't be nil." if( point1.nil? or point2.nil? )
    raise ArgumentError, "Eucledian distance for nD points for n > 3 is currently not implemented." if( (point1.length > 3) or (point2.length > 3 ) )
    # }}}


    x1, y1, z1 = *point1
    x2, y2, z2 = *point2

    if( z1.nil? and z2.nil? )
      puts "Calculating eucledian_distance for 2D coordinates"
      result = Math.sqrt( ( (x2 - x1) ** 2 ) + ( (y2 - y1) ** 2  )  )
    else
      #puts "Calculating eucledian_distance for 3D coordinates"
      #x = x2 - x1
      #y = y2 - y1
      #z = z2 - z1

      #@power_of_two_lookup_table[x] = x**2 if( @power_of_two_lookup_table[ x ].nil? )
      #@power_of_two_lookup_table[y] = y**2 if( @power_of_two_lookup_table[ y ].nil? )
      #@power_of_two_lookup_table[z] = z**2 if( @power_of_two_lookup_table[ z ].nil? )

      #x = @power_of_two_lookup_table[ x ]
      #y = @power_of_two_lookup_table[ y ]
      #z = @power_of_two_lookup_table[ z ]

      result = Math.sqrt( ((x2-x1)**2) + ((y2-y1)**2) + ((z2-z1)**2) )
      # result = C_mathematics.c_eucledian_distance( x1, y1, z1, x2, y2, z2 )
    end

    # Post-condition check
    raise ArgumentError, "The result of this function should be of type numeric, but it is of (#{result.class.to_s})" unless( result.is_a?(Numeric) )

    result
  end # of def eucledian_distance point1, point2 }}}


  # This function turns a nested hash into a nested open struct
  #
  # @author Dave Dribin
  # Reference: http://www.dribin.org/dave/blog/archives/2006/11/17/hashes_to_ostruct/
  #
  # @param    [Object]    object    Value can either be of type Hash or Array, if other then it is returned and not changed
  # @returns  [OStruct]             Returns nested open structs
  def hashes_to_ostruct object # {{{

    return case object
    when Hash
      object = object.clone
      object.each { |key, value| object[key] = hashes_to_ostruct(value) }
      OpenStruct.new( object )
    when Array
      object = object.clone
      object.map! { |i| hashes_to_ostruct(i) }
    else
      object
    end

  end # of def hashes_to_ostruct }}}


end # of class Repair }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100

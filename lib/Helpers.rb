#!/usr/bin/ruby19
#


# @class        class Helpers # {{{
# @brief        The helpers class provides some means of assistance for common tasks
class Helpers

  # @fn       def initialize # {{{
  # @brief    The constructor for the helpers class
  def initialize
  end # }}}


  # @fn       def hashes_to_ostruct object # {{{
  # @brief    This function turns a nested hash into a nested open struct
  #
  # @author   Dave Dribin (Reference: http://www.dribin.org/dave/blog/archives/2006/11/17/hashes_to_ostruct/)
  # @author   Bjoern Rennhak
  #
  # @param    [Object]    object    Value can either be of type Hash or Array, if other then it is returned and not changed
  # @returns  [OStruct]             Returns nested open structs
  def hashes_to_ostruct object = nil

    raise ArgumentError, "Object cannot be nil" if( object.nil? )

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

end # of class Helpers # }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 # }}}


# vim:ts=2:tw=100:wm=100

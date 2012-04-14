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

end # of class Helpers # }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 # }}}


# vim:ts=2:tw=100:wm=100

require "narray"
require "ffi"
class NArray
  class << self
    alias to_na_old to_na
  end
end
require "narray_ffi_c.so"

class NArray
  def to_ptr
    return FFI::Pointer::new( address() ).slice(0, size*element_size)
  end
end

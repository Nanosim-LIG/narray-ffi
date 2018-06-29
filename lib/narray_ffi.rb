require "narray"
require "ffi"
require "narray_ffi_c.so"

class ANArray < NArray

  FFITYPECODES = {
    NArray::BYTE => :char,
    NArray::SINT => :short,
    NArray::INT => :int,
    NArray::SFLOAT => :float,
    NArray::FLOAT => :double,
    NArray::SCOMPLEX => :float,
    NArray::COMPLEX => :double
  }

  def self.new(typecode, alignment, *size)
    raise "Wrong type code" if not FFITYPECODES[typecode]
    raise "Invalid alignment" unless alignment > 0 and ( alignment & (alignment - 1) == 0 )
    total = size.reduce(:*)
    total = 2*total if typecode == NArray::COMPLEX or typecode == NArray::SCOMPLEX
    mem = FFI::MemoryPointer::new( FFITYPECODES[typecode], total + alignment - 1 )
    address = mem.address
    offset = address & (alignment - 1)
    offset = alignment - offset unless offset == 0
    mem = mem.slice(offset, total*mem.type_size)
    return NArray.to_na(mem, typecode, *size)
  end

  def self.byte(alignment, *size)
    return self.new(NArray::BYTE, alignment, *size)
  end

  def self.sint(alignment, *size)
    return self.new(NArray::SINT, alignment, *size)
  end

  def self.int(alignment, *size)
    return self.new(NArray::INT, alignment, *size)
  end

  def self.sfloat(alignment, *size)
    return self.new(NArray::SFLOAT, alignment, *size)
  end

  def self.float(alignment, *size)
    return self.new(NArray::FLOAT, alignment, *size)
  end

  def self.scomplex(alignment, *size)
    return self.new(NArray::SCOMPLEX, alignment, *size)
  end

  def self.complex(alignment, *size)
    return self.new(NArray::COMPLEX, alignment, *size)
  end

  def self.object(alignment, *size)
    return self.new(NArray::OBJECT, alignment, *size)
  end

end

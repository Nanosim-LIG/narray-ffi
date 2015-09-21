require 'narray_ffi'
SIZE = 65536
SIZE2 = 128
SIZE3 = 64
def get_narray
  p = FFI::MemoryPointer::new(:double, SIZE)
  return NArray.to_na(p, NArray::FLOAT)
end

def test_function
  n1 = NArray::float(SIZE).random!
  n2 = get_narray
  GC.start
  (0...SIZE).each { |i|
    n2[i] = n1[i]
  }
  a = n2.to_ptr.read_array_of_double(SIZE)
  n3 = NArray.to_na(a)
  diff = n1 - n3
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
  n4 = NArray.to_na(n2.to_ptr.read_string(SIZE*8), NArray::FLOAT)
  diff = n1 - n4
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
  n4 = NArray.to_na(n2.to_ptr.read_string(SIZE*8), NArray::FLOAT, SIZE)
  diff = n1 - n4
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
  n5 = NArray.to_na(n2.to_ptr, NArray::FLOAT, SIZE2, SIZE3, SIZE/(SIZE2*SIZE3))
  diff = n5.flatten - n1
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
end

test_function
GC.start
puts "Success!"

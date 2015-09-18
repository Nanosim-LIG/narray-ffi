require 'narray_ffi'
def get_narray
  p = FFI::MemoryPointer::new(:double, 16)
  n2 = NArray.to_na(p, NArray::FLOAT)
end

def test_function
  n1 = NArray::float(16).random!
  n2 = get_narray
  GC.start
  (0...16).each { |i|
    n2[i] = n1[i]
  }
  a = n2.to_ptr.read_array_of_double(16)
  n3 = NArray.to_na(a)
  diff = n1 - n3
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
  n4 = NArray.to_na(n2.to_ptr.read_string(16*8), NArray::FLOAT)
  diff = n1 - n4
  diff.each { |e|
    raise "Computation error" if e != 0.0
  }
end

test_function
GC.start

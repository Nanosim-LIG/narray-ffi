#include "ruby.h"
#include "narray.h"

static VALUE
 na_address(VALUE self)
{
  struct NARRAY *ary;
  void * ptr;
  VALUE ret;

  GetNArray(self,ary);
  ptr = ary->ptr;
  ret = ULL2NUM( sizeof(ptr) == 4 ? (unsigned long long int) (unsigned long int) ptr : (unsigned long long int) ptr );
  return ret;
}

static struct NARRAY*
 na_alloc_struct_empty(int type, int rank, int *shape)
{
  int total=1, total_bak;
  int i, memsz;
  struct NARRAY *ary;

  for (i=0; i<rank; ++i) {
    if (shape[i] < 0) {
      rb_raise(rb_eArgError, "negative array size");
    } else if (shape[i] == 0) {
      total = 0;
      break;
    }
    total_bak = total;
    total *= shape[i];
    if (total < 1 || total > 2147483647 || total/shape[i] != total_bak) {
      rb_raise(rb_eArgError, "array size is too large");
    }
  }

  if (rank<=0 || total<=0) {
    /* empty array */
    ary = ALLOC(struct NARRAY);
    ary->rank  =
    ary->total = 0;
    ary->shape = NULL;
    ary->ptr   = NULL;
    ary->type  = type;
  }
  else {
    memsz = na_sizeof[type] * total;

    if (memsz < 1 || memsz > 2147483647 || memsz/na_sizeof[type] != total) {
      rb_raise(rb_eArgError, "allocation size is too large");
    }

    /* Garbage Collection */
#ifdef NARRAY_GC
    mem_count += memsz;
    if ( mem_count > na_gc_freq ) { rb_gc(); mem_count=0; }
#endif

    ary        = ALLOC(struct NARRAY);
    ary->shape = ALLOC_N(int,  rank);

    ary->rank  = rank;
    ary->total = total;
    ary->type  = type;
    for (i=0; i<rank; ++i)
      ary->shape[i] = shape[i];
  }
  ary->ref = Qtrue;
  return ary;
}

static void
 na_free_empty(struct NARRAY* ary)
{
  if ( ary->total > 0 ) {
    xfree(ary->shape);
  }
  xfree(ary);
}

static void
 na_mark_ref_empty(struct NARRAY *ary)
{
  struct NARRAY *a2;

  rb_gc_mark( ary->ref );

}

static VALUE
 na_make_object_empty(int type, int rank, int *shape, VALUE klass, VALUE pointer)
{
  struct NARRAY *na;

  na = na_alloc_struct_empty(type, rank, shape);
  na->ref = pointer;

  return Data_Wrap_Struct(klass, na_mark_ref_empty, na_free_empty, na);
}


static VALUE
 na_pointer_to_na(int argc, VALUE *argv, VALUE pointer)
{
  struct NARRAY *ary;
  VALUE v;
  void * ptr;
  VALUE address;
  int i, type, len=1, pointer_len, *shape, rank=argc-1;

  if (argc < 1)
    rb_raise(rb_eArgError, "Type and Size Arguments required");

  type = na_get_typecode(argv[0]);
  if (type==NA_ROBJ)
    rb_raise(rb_eArgError, "Invalid type");

  address = rb_funcall(pointer, rb_intern("address"), 0);
  ptr = sizeof(ptr) == 4 ? (void *) NUM2ULONG(address) : (void *) NUM2ULL(address);

  pointer_len = NUM2INT(rb_funcall(pointer, rb_intern("size"), 0));

  if (argc == 1) {
    rank = 1;
    shape = ALLOCA_N(int,rank);
    if ( pointer_len % na_sizeof[type] != 0 )
      rb_raise(rb_eArgError, "pointer size mismatch");
    shape[0] = pointer_len / na_sizeof[type];
  }
  else {
    shape = ALLOCA_N(int,rank);
    for (i=0; i<rank; i++)
      len *= shape[i] = NUM2INT(argv[i+1]);
    len *= na_sizeof[type];
    if ( len != pointer_len )
      rb_raise(rb_eArgError, "pointer size mismatch");
  }

  v = na_make_object_empty( type, rank, shape, cNArray, pointer );
  GetNArray(v,ary);
  ary->ptr = ptr;

  return v;
}

static VALUE
 na_s_to_na_pointer(int argc, VALUE *argv, VALUE klass)
{
  VALUE mod;
  VALUE klass_p;
  if (argc < 1){
    rb_raise(rb_eArgError, "Argument is required");
  }
  mod = rb_const_get(rb_cObject, rb_intern("FFI"));
  if (mod != Qnil) {
    klass_p = rb_const_get(mod, rb_intern("Pointer"));
    if ( rb_funcall(argv[0], rb_intern("kind_of?"), 1, klass_p) == Qtrue ){
      return na_pointer_to_na(argc-1,argv+1,argv[0]);
    }
  }
  rb_funcall2(klass, rb_intern("to_na_old"), argc, argv);
}

void Init_narray_ffi_c() {
  ID id;
  VALUE klass;
  id = rb_intern("NArray");
  klass = rb_const_get(rb_cObject, id);
  rb_define_private_method(klass, "address", na_address, 0);
  rb_define_singleton_method(klass, "to_na", na_s_to_na_pointer, -1);
  rb_define_singleton_method(klass, "to_narray", na_s_to_na_pointer, -1);
}


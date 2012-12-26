# coding: utf-8
require "rubygems"
require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

module CTest
  extend FFI::Library
  ffi_lib FFI::Library::LIBC

  attach_function :strcat, [:pointer, :pointer], :pointer
end

describe "MemoryPointer" do
  it "makes a pointer from a string" do
    m = FFI::MemoryPointer.from_string("FFI is Awesome")
    m.total.should eq 15
    m.type_size.should eq 1
  end

  it "makes a pointer from a string with multibyte characters" do
    m = FFI::MemoryPointer.from_string("ぱんだ")
    m.total.should eq 10
    m.type_size.should eq 1
  end

  it "reads back a string" do
    m = FFI::MemoryPointer.from_string("FFI is Awesome")
    m.read_string.should eq "FFI is Awesome"
  end
  
  it "makes a pointer for a certain number of bytes" do
    m = FFI::MemoryPointer.new(8)
    m.write_array_of_int([1,2])
    m.read_array_of_int(2).should eq [1,2]
  end

  it "allows access to an element of the pointer (as an array)" do
    m = FFI::MemoryPointer.new(:int, 2)
    m.write_array_of_int([1,2])
    m[0].read_int.should eq 1
    m[1].read_int.should eq 2
  end
  
  it "allows writing as an int" do
    m = FFI::MemoryPointer.new(:int)
    m.write_int(1)
    m.read_int.should eq 1
  end
  
  it "allows writing as a long" do
    m = FFI::MemoryPointer.new(:long)
    m.write_long(10)
    m.read_long.should eq 10
  end
  
  it "raises an error if you try putting a long into a pointer of size 1" do
    m = FFI::MemoryPointer.new(1)
    lambda { m.write_long(10) }.should raise_error
  end
  
  it "raises an error if you try putting an int into a pointer of size 1" do
    m = FFI::MemoryPointer.new(1)
    lambda { m.write_int(10) }.should raise_error
  end
#  it "does not raise IndexError for opaque pointers" do
#    m = FFI::MemoryPointer.new(8)
#    p2 = FFI::MemoryPointer.new(1024)
#    m.write_long(p2.address)
#    p = m.read_pointer
#    lambda { p.write_int(10) }.should_not raise_error
#  end
  
  it "makes a pointer for a certain type" do
    m = FFI::MemoryPointer.new(:int)
    m.write_int(10)
    m.read_int.should eq 10
  end
  
  it "makes a memory pointer for a number of a certain type" do
    m = FFI::MemoryPointer.new(:int, 2)
    m.write_array_of_int([1,2])
    m.read_array_of_int(2).should eq [1,2]
  end
  
  it "makes a pointer for an object responding to #size" do
    m = FFI::MemoryPointer.new(Struct.new(:size).new(8))
    m.write_array_of_int([1,2])
    m.read_array_of_int(2).should eq [1,2]
  end

  it "makes a pointer for a number of an object responding to #size" do
    m = FFI::MemoryPointer.new(Struct.new(:size).new(4), 2)
    m.write_array_of_int([1,2])
    m.read_array_of_int(2).should eq [1,2]
  end  
  it "MemoryPointer#address returns correct value" do
    m = FFI::MemoryPointer.new(:long_long)
    magic = 0x12345678
    m.write_long(magic)
    m.read_pointer.address.should eq magic
  end
  it "MemoryPointer#null? returns true for zero value" do
    m = FFI::MemoryPointer.new(:long_long)
    m.write_long(0)    
    m.read_pointer.null?.should eq true
  end
  it "MemoryPointer#null? returns false for non-zero value" do
    m = FFI::MemoryPointer.new(:long_long)
    m.write_long(0x12345678)
    m.read_pointer.null?.should eq false
  end
end

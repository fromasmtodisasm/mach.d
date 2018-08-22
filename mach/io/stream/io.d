module mach.io.stream.io;

private:

import mach.traits.iter : isIterable;
import mach.io.stream.exceptions;
import mach.io.stream.templates;

/++ Docs

Stream types support read and write operations via their `readbufferv` and
`writebufferv` methods.
This module implements a number of abstractions that allow reading from and
writing to a stream in more abstract ways, using the `read` and `write`
functions.

+/

unittest{ /// Example
    import mach.io.stream.memorystream : asstream;
    // Acquire a stream based on an array
    int[] array = [0, 1, 2, 3, 4, 5, 6];
    auto stream = array.asstream;
    // Read a single value at a time
    assert(stream.read!int == 0);
    assert(stream.read!int == 1);
    // Read multiple values into an array
    assert(stream.read!int(2) == [2, 3]);
    // Write a single value at a time
    stream.write!int(100);
    assert(array == [0, 1, 2, 3, 100, 5, 6]);
    // Write multiple values at once
    stream.write!(int[])([200, 300]);
    assert(array == [0, 1, 2, 3, 100, 200, 300]);
    // No more data in the stream!
    assert(stream.eof);
}

public:



/// Read the given number of values to a buffer represented by a pointer.
size_t readbuffer(T, Stream)(auto ref Stream stream, T* buffer, size_t count = 1) if(
    isInputStream!Stream
){
    return stream.readbufferv(buffer, T.sizeof, count);
}

/// Read values to a buffer represented by an array.
size_t readbuffer(T, Stream)(auto ref Stream stream, T[] buffer) if(
    isInputStream!Stream
){
    return stream.readbufferv(buffer.ptr, T.sizeof, buffer.length);
}



/// Read a single value of an arbitrary type from an input stream.
/// Not an especially meaningful operation for anything other than primitives
/// and structs.
auto read(T, Stream)(auto ref Stream stream) if(isInputStream!Stream){
    T value = void;
    auto result = stream.readbuffer!T(&value, 1);
    if(result != T.sizeof) throw new StreamReadException();
    return value;
}

/// Read the given number of values of an arbitrary type from an input stream.
/// Not an especially meaningful operation for anything other than primitives
/// and structs.
auto read(T, Stream)(auto ref Stream stream, in size_t count) if(isInputStream!Stream){
    T[] values;
    values.reserve(count);
    foreach(size_t i; 0 .. count) values ~= stream.read!T;
    return values;
}

/// Skip some number of bytes in the stream by reading them.
/// Returns the number of bytes skipped, which may be fewer than the count
/// passed.
size_t readskip(Stream)(auto ref Stream stream, in size_t count) if(isInputStream!Stream){
    ubyte[256] buffer = void;
    size_t skipped = 0;
    while(skipped < count){
        immutable size_t toskip = (
            (count - skipped < buffer.length) ? (count - skipped) : buffer.length
        );
        auto read = stream.readbufferv(
            cast(void*) buffer.ptr, typeof(buffer[0]).sizeof, toskip
        );
        skipped += read;
        if(read < toskip) break;
    }
    return skipped;
}



/// Write the given number of values from a buffer represented by a pointer.
size_t writebuffer(T, Stream)(auto ref Stream stream, in T* buffer, size_t count = 1) if(
    isOutputStream!Stream
){
    return stream.writebufferv(cast(void*) buffer, T.sizeof, count);
}

/// Write values from a buffer represented by an array.
size_t writebuffer(T, Stream)(auto ref Stream stream, in T[] buffer) if(
    isOutputStream!Stream
){
    return stream.writebuffer!T(buffer.ptr, buffer.length);
}



void write(T, Stream)(auto ref Stream stream, auto ref T value) if(
    isOutputStream!Stream && !isIterable!T
){
    auto result = stream.writebuffer(&value, 1);
    if(result != T.sizeof) throw new StreamWriteException();
}

void write(Iter, Stream)(auto ref Stream stream, auto ref Iter values) if(
    isOutputStream!Stream && isIterable!Iter
){
    foreach(value; values) stream.write!(typeof(value))(value);
}

/// Skip some number of bytes in the stream by writing to them.
/// Returns the number of bytes skipped, which may be fewer than the count
/// passed.
size_t writeskip(Stream)(auto ref Stream stream, in size_t count, in ubyte data = 0) if(
    isOutputStream!Stream
){
    import core.stdc.string : memset;
    ubyte[256] buffer = void;
    memset(cast(void*) buffer.ptr, data, buffer.length);
    size_t skipped = 0;
    while(skipped < count){
        immutable size_t toskip = (
            (count - skipped < buffer.length) ? (count - skipped) : buffer.length
        );
        auto written = stream.writebuffer(
            cast(void*) buffer.ptr, typeof(buffer[0]).sizeof, toskip
        );
        skipped += written;
        if(written < toskip) break;
    }
    return skipped;
}



unittest{
    // TODO
}

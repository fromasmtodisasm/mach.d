module mach.traits.array;

private:

//

public:



/// Determine if a type is a static or dynamic array.
enum isArray(alias T) = isArray!(typeof(T));
/// ditto
template isArray(T){
    enum bool isArray = is(typeof({
        auto x(X)(X[] y){}
        x(T.init);
    }));
}



/// Determine whether some type is an array of a specific element type.
enum isArrayOf(E, alias T) = isArrayOf!(E, typeof(T));
/// ditto
template isArrayOf(E, T){
    enum bool isArrayOf = isArray!T && is(typeof({
        E[] x = T.init.dup;
    }));
}



/// Determine if a type is a static array.
enum isStaticArray(alias T) = isStaticArray!(typeof(T));
/// ditto
template isStaticArray(T){
    enum bool isStaticArray = is(typeof({
        auto x(X, size_t n)(X[n] y){}
        x(T.init);
    }));
}

/// Determine if a type is a dynamic array.
template isDynamicArray(T...) if(T.length == 1){
    enum bool isDynamicArray = isArray!T && !isStaticArray!T;
}





unittest{
    int[] dints;
    int[4] sints;
    static assert(isArray!(dints));
    static assert(isArray!(sints));
    static assert(isArray!(int[0]));
    static assert(isArray!(int[1]));
    static assert(isArray!(int[2]));
    static assert(isArray!(string[4]));
    static assert(isArray!(int[]));
    static assert(isArray!(string[]));
    static assert(isArray!(int[][]));
    static assert(!isArray!(void));
    static assert(!isArray!(int));
}
unittest{
    static assert(isArrayOf!(int, int[]));
    static assert(isArrayOf!(int[], int[][]));
    static assert(isArrayOf!(const(int), const(int)[]));
    static assert(isArrayOf!(const(int), int[]));
    static assert(isArrayOf!(immutable(char), string));
    static assert(!isArrayOf!(void, void));
    static assert(!isArrayOf!(int, void));
    static assert(!isArrayOf!(void, int));
    static assert(!isArrayOf!(int, int));
    static assert(!isArrayOf!(int, double[]));
    static assert(!isArrayOf!(int[], int));
    static assert(!isArrayOf!(int, int[][]));
}
unittest{
    int[4] ints;
    static assert(isStaticArray!(ints));
    static assert(isStaticArray!(int[0]));
    static assert(isStaticArray!(int[1]));
    static assert(isStaticArray!(int[2]));
    static assert(isStaticArray!(string[4]));
    static assert(!isStaticArray!(void));
    static assert(!isStaticArray!(int));
    static assert(!isStaticArray!(int[]));
    static assert(!isStaticArray!(string[]));
}
unittest{
    int[] ints;
    static assert(isDynamicArray!(ints));
    static assert(isDynamicArray!(int[]));
    static assert(isDynamicArray!(string));
    static assert(isDynamicArray!(int[][]));
    static assert(!isDynamicArray!(void));
    static assert(!isDynamicArray!(int));
    static assert(!isDynamicArray!(int[0]));
    static assert(!isDynamicArray!(int[1]));
    static assert(!isDynamicArray!(int[2]));
    static assert(!isDynamicArray!(string[4]));
}

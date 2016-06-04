module mach.traits.index;

private:

import std.meta : AliasSeq;
import std.traits : Parameters;
import std.traits : isNumeric, isArray, isAssociativeArray, KeyType;

public:



enum canIndexPrimitive(T) = (
    isArray!T || isAssociativeArray!T
);

enum canIndex(T) = (
    canIndexPrimitive!T || is(typeof(T.opIndex))
);

template canIndex(T, Indexes...){
    enum bool canIndex = is(typeof((inout int = 0){
        auto result = T.init[Indexes.init];
    }));
}

template IndexParameters(T) if(canIndex!T){
    static if(isArray!T){
        alias IndexParameters = AliasSeq!(size_t);
    }else static if(isAssociativeArray!T){
        alias IndexParameters = AliasSeq!(KeyType!T);
    }else{
        alias IndexParameters = Parameters!(T.opIndex);
    }
}

template hasSingleIndexParameter(T){
    enum bool hasSingleIndexParameter = canIndex!T && (
        canIndexPrimitive!T ||
        is(typeof((inout int = 0){
            static assert(IndexParameters!T.length == 1);
        }))
    );
}

template SingleIndexParameter(T) if(hasSingleIndexParameter!T){
    alias SingleIndexParameter = IndexParameters!T[0];
}

template hasNumericIndex(T){
    enum bool hasNumericIndex = is(typeof((inout int = 0){
        auto value = T.init[0];
    }));
}



version(unittest){
    private struct IndexTest{
        int value;
        auto opIndex(in int index) const{
            return this.value + index;
        }
    }
    private struct IndexMultiTest{
        real value;
        auto opIndex(in real x, in float y) const{
            return this.value + x + y;
        }
    }
}
unittest{
    // canIndex
    static assert(canIndex!(int[]));
    static assert(canIndex!IndexTest);
    static assert(canIndex!IndexMultiTest);
    static assert(!canIndex!int);
    static assert(canIndex!(int[], size_t));
    static assert(canIndex!(int[][], size_t));
    static assert(canIndex!(string, size_t));
    static assert(canIndex!(IndexMultiTest, real, real));
    static assert(!canIndex!(string, string));
    static assert(!canIndex!(IndexMultiTest, int));
    // IndexParameters
    static assert(is(IndexParameters!(int[])[0] == size_t));
    static assert(is(IndexParameters!IndexTest[0] == const(int)));
    static assert(is(IndexParameters!IndexMultiTest[0] == const(real)));
    static assert(is(IndexParameters!IndexMultiTest[1] == const(float)));
    // hasSingleIndexParameter
    static assert(hasSingleIndexParameter!(int[]));
    static assert(hasSingleIndexParameter!IndexTest);
    static assert(!hasSingleIndexParameter!IndexMultiTest);
    // SingleIndexParameter
    static assert(is(SingleIndexParameter!(int[]) == size_t));
    static assert(is(SingleIndexParameter!IndexTest == const(int)));
}

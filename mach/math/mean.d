module mach.math.mean;

private:

import mach.traits : isNumeric, isIntegral, isFiniteIterable, ElementType, Unqual;

/++ Docs

This module implements the `mean` function, which accepts an iterable of
numeric primitives and calculates the arithmetic mean of those values.

+/

unittest{ /// Example
    assert([5, 10, 15].mean == 10);
    assert([0.25, 0.5, 0.75, 1.0].mean == 0.625);
}

/++ Docs

When not compiled in release mode, `mean` throws a `MeanEmptyInputError` when
the input iterable was empty. In release mode, this error reporting is omitted.

+/

unittest{ /// Example
    import mach.test.assertthrows : assertthrows;
    assertthrows!MeanEmptyInputError({
        new int[0].mean; // Can't calculate mean with an empty input!
    });
}

/++ Docs

`mean` can also be called with two numeric inputs, and will determine their
average without errors related to overflow or truncation of integers.

+/

unittest{ /// Example
    assert(mean(int.max, int.max - 10) == int.max - 5);
}

public:



/// Error thrown when the input to `mean` was an empty iterable.
class MeanEmptyInputError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Cannot determine mean of an empty sequence of values.", file, line, null);
    }
}



/// Determine whether it is possible to get the mean given an iterable of values.
template canGetMean(T){
    static if(isFiniteIterable!T){
        enum bool canGetMean = isNumeric!(ElementType!T);
    }else{
        enum bool canGetMean = false;
    }
}



/// Calculates the arithmetic mean of some inputs using a
/// divide-and-conquer approach in order to minimize error.
/// Throws a `MeanEmptyInputError` when the input was empty.
auto mean(T)(auto ref T values) if(canGetMean!T){
    struct Mean{
        double value; /// Average of the considered values.
        size_t count; /// Number of values considered for this average.
    }
    
    Mean[] stack;
    
    foreach(value; values){
        stack ~= Mean(value, 1);
        while(stack.length > 1 && stack[$-2].count == stack[$-1].count){
            immutable a = stack[$-2];
            immutable b = stack[$-1];
            stack.length -= 1;
            stack[$-1] = Mean((a.value / 2) + (b.value / 2), a.count * 2);
        }
    }
    
    while(stack.length > 1){
        immutable a = stack[$-2];
        immutable b = stack[$-1];
        stack.length -= 1;
        assert(a.count > b.count); // Should be guaranteed by previous loop.
        immutable csum = a.count + b.count;
        stack[$-1] = Mean(((a.value * a.count) + (b.value * b.count)) / csum, csum);
    }
    
    version(assert){
        static const error = new MeanEmptyInputError();
        if(stack.length == 0) throw error;
    }
    
    return cast(ElementType!T) stack[0].value;
}



/// Calculates the arithmetic mean of two numeric inputs.
/// Will not overflow or produce incorrect results for integer inputs.
T mean(T)(in T a, in T b) if(isNumeric!T){
    static if(isIntegral!T){
        return a / 2 + b / 2 + (a & b & 1);
    }else{
        return a / 2 + b / 2;
    }
}



private version(unittest) {
    import mach.test.assertthrows : assertthrows;
}

/// Empty array input
unittest {
    assertthrows!MeanEmptyInputError({
        new int[0].mean;
    });
}

/// Array inputs
unittest {
    assert([0].mean == 0);
    assert([100.0].mean == 100.0);
    assert([0.0, 1.0].mean == 0.5);
    assert([0, 1, 2, 3, 4, 5, 6].mean == 3);
}

/// Range inputs
unittest {
    struct IntRange{
        int end, i = 0;
        @property bool empty() const{return this.i == this.end;}
        @property auto front() const{return this.i;}
        void popFront(){this.i++;}
    }
    assert(IntRange(5).mean == 2);
    assert(IntRange(101).mean == 50);
    assert(IntRange(1001).mean == 500);
    assert(IntRange(100001).mean == 50000);
}

/// Variadic arguments
unittest {
    assert(mean(0, 0) == 0);
    assert(mean(0, 1) == 0);
    assert(mean(0, 2) == 1);
    assert(mean(-1.0, 1.0) == 0.0);
    assert(mean(int.max, int.max - 10) == int.max - 5);
}

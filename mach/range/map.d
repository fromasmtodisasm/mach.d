module mach.range.map;

private:

import mach.traits : isRange, isRandomAccessRange, isSlicingRange, ElementType;
import mach.traits : isElementTransformation;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canMap(Iter, alias transform) = (
    validAsRange!Iter && isElementTransformation!(transform, Iter)
);

enum canMapRange(Range, alias transform) = (
    isRange!Range && isElementTransformation!(transform, Range)
);



/// Returns a range whose elements are those of the given iterable transformed
/// by some function.
auto map(alias transform, Iter)(Iter iter) if(canMap!(Iter, transform)){
    auto range = iter.asrange;
    return MapRange!(transform, typeof(range))(range);
}



struct MapRange(alias transform, Range) if(canMapRange!(Range, transform)){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar Save Back`,
        `return transform(this.source.front);`,
        `this.source.popFront();`
    );
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
    }
    
    static if(isRandomAccessRange!Range){
        auto ref opIndex(size_t index){
            return transform(this.source[index]);
        }
    }
    static if(isSlicingRange!Range){
        typeof(this) opSlice(size_t low, size_t high){
            return typeof(this)(this.source[low .. high]);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Map", {
        alias square = (n) => (n * n);
        int[] ones = [1, 1, 1, 1];
        int[] empty = new int[0];
        test([1, 2, 3, 4].map!square.equals([1, 4, 9, 16]));
        test(ones.map!square.equals(ones));
        test("Empty input", empty.map!square.equals(empty));
        testeq("Length", [1, 2, 3].map!square.length, 3);
        testeq("Random access", [2, 3].map!square[1], 9);
        test("Slicing", [1, 2, 3, 4].map!square[1 .. $-1].equals([4, 9]));
    });
}

module mach.range.map;

private:

import mach.traits : isRange, isIndexedRange, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canMap(Iter, alias transform) = (
    validAsRange!Iter && validMapTransformation!(Iter, transform)
);
enum canMapRange(Range, alias transform) = (
    isRange!Range && validMapTransformation!(Range, transform)
);

template validMapTransformation(Iter, alias transform){
    enum bool validMapTransformation = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto result = transform(Element.init);
    }));
}



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
    
    static if(isIndexedRange!Range){
        import mach.traits : IndexParameters;
        auto ref opIndex(IndexParameters!Range index){
            return transform(this.source.opIndex(index));
        }
    }
    
    // TODO: Slice
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Map", {
        int[] ones = [1, 1, 1, 1];
        int[] empty = new int[0];
        alias square = (n) => (n * n);
        test([1, 2, 3, 4].map!square.equals([1, 4, 9, 16]));
        test(ones.map!square.equals(ones));
        test("Empty input", empty.map!square.equals(empty));
        testeq("Length", [1, 2, 3].map!square.length, 3);
        testeq("Random access", [2, 3].map!square[1], 9);
    });
}
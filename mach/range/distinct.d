module mach.range.distinct;

private:

import mach.traits : isRange, isBidirectionalRange, isSavingRange;
import mach.traits : canHash, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin;

public:



enum validDistinctBy(Iter, alias by) = (
    canHash!(typeof(by(ElementType!Iter.init)))
);

enum canDistinct(Iter, alias by) = (
    validAsRange!Iter && validDistinctBy!(Iter, by)
);

enum canDistinctRange(Range, alias by) = (
    isRange!Range && validDistinctBy!(Range, by)
);

alias DefaultDistinctBy = (element) => (element);



/// Create a range which returns only those values from the original iterable
/// that are distinct from all previous values. By default, each element itself
/// is tested for uniqueness; however an attribute of some element can be tested
/// for uniqueness by providing a different by alias. For example,
///     input.distinct!((e) => (e.name))
/// would iterate over those elements of input with distinct names.
auto distinct(alias by = DefaultDistinctBy, Iter)(Iter iter) if(canDistinct!(Iter, by)){
    auto range = iter.asrange;
    return DistinctRange!(typeof(range), by)(range);
}



struct DistinctRange(Range, alias by = DefaultDistinctBy) if(canDistinctRange!(Range, by)){
    mixin MetaRangeEmptyMixin!(Range, `source`);
    alias ByType = typeof(by(ElementType!Range.init));
    
    alias History = bool[ByType]; // TODO: Proper set?
    
    Range source;
    History history;
    
    this(typeof(this) range){
        this(range.source, range.history);
    }
    this(Range source){
        this.source = source;
    }
    this(Range source, History history){
        this.source = source;
        this.history = history;
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.history[by(this.source.front)] = true;
        this.source.popFront();
        while(!this.source.empty && by(this.source.front) in this.history){
            this.source.popFront();
        }
    }
    
    // Note that iterating backwards doesn't necessarily result in the reverse
    // of running forwards.
    static if(isBidirectionalRange!Range){
        @property auto ref back(){
            return this.source.back;
        }
        void popBack(){
            this.history[by(this.source.back)] = true;
            this.source.popBack();
            while(!this.source.empty && by(this.source.back) in this.history){
                this.source.popBack();
            }
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source, this.history);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.reversed : reversed;
}
unittest{
    tests("Distinct", {
        tests("Basic iteration", {
            test("aabacba".distinct.equals("abc"));
            test("nnnnnnnnnnnnnnn".distinct.equals("n"));
            test("hi".distinct.equals("hi"));
            test("x".distinct.equals("x"));
            test("".distinct.equals(""));
        });
        tests("Saving", {
            auto range = "aabc".distinct;
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 'b');
            testeq(saved.front, 'a');
        });
        tests("By", {
            auto pairs = [
                [0, 1], [0, 2], [0, 3],
                [1, 1], [1, 2], [1, 3]
            ];
            auto range = pairs.distinct!((pair) => (pair[0]));
            test("Forward", range.equals([[0, 1], [1, 1]]));
            test("Reverse", range.reversed.equals([[1, 3], [0, 3]]));
        });
    });
}
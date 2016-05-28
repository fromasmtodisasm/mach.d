module mach.traits.element;

private:

import std.traits : isArray, isDelegate, isSomeFunction, fullyQualifiedName;
import std.traits : Parameters, ReturnType;
import mach.traits.iter : isRange;
import mach.traits.op : hasOpApply, hasOpApplyReverse;

public:



template ArrayElementType(Array) if(isArray!Array){
    alias ArrayElementType = typeof(Array.init[0]);
}

template RangeElementType(Range) if(isRange!Range){
    static if(isSomeFunction!(Range.init.front)){
        alias RangeElementType = ReturnType!(Range.init.front);
    }else{
        alias RangeElementType = typeof(Range.init.front);
    }
}

private template OpApplyGenericElementType(Iter, alias op){
    alias ApplyParams = Parameters!op;
    static assert(
        ApplyParams.length == 1 && isDelegate!(ApplyParams[0]),
        fullyQualifiedName!Iter ~ " has invalid arguments for opApply."
    );
    alias Delegate = ApplyParams[0];
    alias DelegateParams = Parameters!Delegate;
    static assert(DelegateParams.length == 1);
    alias OpApplyGenericElementType = DelegateParams[0];
}
template OpApplyElementType(Iter) if(hasOpApply!Iter){
    alias OpApplyElementType = OpApplyGenericElementType!(Iter, Iter.opApply);
}
template OpApplyReverseElementType(Iter) if(hasOpApplyReverse!Iter){
    alias OpApplyReverseElementType = OpApplyGenericElementType!(Iter, Iter.opApplyReverse);
}



/// Get the element type of anything that can be iterated.
template ElementType(Iter){
    static if(isArray!Iter){
        alias ElementType = ArrayElementType!Iter;
    }else static if(isRange!Iter){
        alias ElementType = RangeElementType!Iter;
    }else static if(hasOpApply!Iter){
        alias ElementType = OpApplyElementType!Iter;
    }else static if(hasOpApplyReverse!Iter){
        alias ElementType = OpApplyReverseElementType!Iter;
    }else{
        static assert(
            false, "Unable to determine element type for " ~ fullyQualifiedName!Iter ~ "."
        );
    }
}



version(unittest){
    struct RangeElementTest{
        int value;
        @property auto front() const{
            return this.value;
        }
        void popFront(){
            this.value++;
        }
        enum bool empty = false;
    }
    struct ApplyElementTest{
        int opApply(in int delegate(ref string item) each){
            return 0;
        }
    }
    struct ApplyReverseElementTest{
        int opApplyReverse(in int delegate(ref string item) each){
            return 0;
        }
    }
}
unittest{
    // Arrays
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(real[][]) == real[]));
    // Ranges
    static assert(is(ElementType!RangeElementTest == const(int)));
    // OpApply
    static assert(is(ElementType!ApplyElementTest == string));
    // OpApplyReverse
    static assert(is(ElementType!ApplyReverseElementTest == string));
}

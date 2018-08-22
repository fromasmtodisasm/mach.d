module mach.meta.adjoin;

private:

import mach.types.types : Types;

/++ Docs: mach.meta.adjoin

The `Adjoin` template generates a function from several input functions,
where the return value of the generated function is a tuple containing each
value returned by the adjoined functions.

+/

unittest{ /// Example
    alias fn = Adjoin!(e => e - 1, e => e + 1);
    auto result = fn(0);
    assert(result[0] == -1);
    assert(result[1] == 1);
}

/++ Docs: mach.meta.adjoin

A function generated using Adjoin will return a tuple unconditionally, even
when adjoining only one function.

The module also defines an `AdjoinFlat` template, which produces the same
behavior as `Adjoin` except for the case where its input is a single function.
In that case, the template is aliased to that function and does not wrap the
output in a tuple, as `Adjoin` would.

+/

unittest{ /// Example
    alias fn = AdjoinFlat!(e => e - 1);
    assert(fn(0) == -1); // Output is the same as the passed function
}

unittest{ /// Example
    alias fn = AdjoinFlat!(e => e - 1, e => e + 1);
    assert(fn(0).length == 2); // Output is a tuple
}

public:



/// Used by functions constructed by Adjoin to determine whether the function
/// is able to be called using the given arguments.
template canAdjoin(FTypes, Args...){
    alias F = FTypes.types;
    static if(FTypes.length == 0){
        enum bool canAdjoin = true;
    }else static if(FTypes.length == 1){
        enum bool canAdjoin = is(typeof({auto x = F[0](Args.init);}));
    }else{
        enum bool canAdjoin = (
            canAdjoin!(Types!(F[0]), Args) &&
            canAdjoin!(Types!(F[1 .. $]), Args)
        );
    }
}



/// A function which returns a tuple, where each item in the tuple corresponds
/// to the same-index function used in the template declaration called with
/// the same arguments.
template Adjoin(F...){
    auto Adjoin(Args...)(auto ref Args args) if(canAdjoin!(Types!F, Args)){
        import mach.types : tuple;
        static if(F.length == 0){
            return tuple();
        }else static if(F.length == 1){
            return tuple(F[0](args));
        }else{
            return tuple(F[0](args), .Adjoin!(F[1 .. $])(args).expand);
        }
    }
}



/// Same as Adjoin, but when there is only one function a single value is
/// returned instead of a tuple containing a single value. Does not allow
/// an empty sequence of input functions.
template AdjoinFlat(F...) if(F.length > 0){
    static if(F.length == 1){
        alias AdjoinFlat = F[0];
    }else{
        alias AdjoinFlat = Adjoin!F;
    }
}



unittest{
    static assert(canAdjoin!(Types!(e => e + 1), int));
    static assert(!canAdjoin!(Types!(e => e + 1), string));
    static assert(canAdjoin!(Types!(e => e, e => e), int));
}
unittest{
    alias fn = Adjoin!();
    auto result = fn(0);
    static assert(result.length == 0);
}
unittest{
    alias fn = Adjoin!(e => e);
    auto result = fn(0);
    static assert(result.length == 1);
    assert(result[0] == 0);
}
unittest{
    alias fn = Adjoin!(e => e, e => e + 1, e => e + 2);
    auto result = fn(0);
    static assert(result.length == 3);
    assert(result[0] == 0);
    assert(result[1] == 1);
    assert(result[2] == 2);
}
unittest{
    static assert(!is(typeof({AdjoinFlat!();})));
    alias fn1 = AdjoinFlat!(e => e);
    static assert(is(typeof(fn1(int(0))) == int));
    alias fn2 = AdjoinFlat!(e => e, e => e);
    static assert(fn2(0).length == 2);
}

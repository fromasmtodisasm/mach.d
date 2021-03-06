module mach.meta.map;

private:

import mach.meta.aliases : Aliases;
import mach.meta.ctint : ctint;

/++ Docs: mach.meta.map

Implements the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for template arguments.
The first template argument to `Map` represents a transformation function, which
is applied to the sequence represented by the subsequent template arguments.

+/

unittest { /// Example
    enum AddOne(alias n) = n + 1;
    alias added = Map!(AddOne, 3, 2, 1);
    static assert(added.length == 3);
    static assert(added[0] == 4);
    static assert(added[1] == 3);
    static assert(added[2] == 2);
}

public:



private string MapMixin(in size_t args) {
    string codegen = ``;
    foreach(i; 0 .. args) {
        if(i != 0) codegen ~= `, `;
        codegen ~= `transform!(T[` ~ ctint(i) ~ `])`;
    }
    return `Aliases!(` ~ codegen ~ `);`;
}

template Map(alias transform, T...) {
    static if(T.length == 0) {
        alias Map = Aliases!();
    }
    else static if(T.length == 1) {
        alias Map = Aliases!(transform!(T[0]));
    }
    else {
        mixin(`alias Map = ` ~ MapMixin(T.length));
    }
}



private version(unittest) {
    import mach.traits.primitives : isIntegral;
    template Embiggen(T) {
        static if(is(T == int)) {
            alias Embiggen = long;
        }
        else static if(is(T == float)) {
            alias Embiggen = double;
        }
        else {
            alias Embiggen = T;
        }
    }
}

unittest {
    static assert(is(
        Map!(Embiggen, int, float, double) == Aliases!(long, double, double)
    ));
    alias integrals = Map!(isIntegral, int, float, double);
    static assert(integrals.length == 3);
    static assert(integrals[0] == true);
    static assert(integrals[1] == false);
    static assert(integrals[2] == false);
}

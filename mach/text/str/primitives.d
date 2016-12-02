module mach.text.str.primitives;

private:

import mach.traits : isIntegral, isFloatingPoint, isCharacter;
import mach.traits : isImaginary, isComplex, Unimaginary, isPointer;
import mach.traits : isFiniteIterable, isString, isCharString;
import mach.traits : isWString, isDString, Unqual, isArray, hasNumericLength;
import mach.traits : isEnumType, enummembername, PointerType;
import mach.text.parse.numeric : writeint, WriteBase, writefloat;
import mach.text.utf : utf8encode;
import mach.text.str.settings;

alias writeptr = WriteBase!16;

public:



string booleantostring(in bool value){
    return value ? "true" : "false";
}

string integertostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isIntegral!T){
    static if(settings.integers){
        return Unqual!T.stringof ~ "(" ~ value.writeint ~ ")";
    }else{
        return value.writeint;
    }
}

string floattostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isFloatingPoint!T){
    static if(settings.floats){
        return Unqual!T.stringof ~ "(" ~ value.writefloat ~ ")";
    }else{
        return value.writefloat;
    }
}

string imaginarytostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isImaginary!T){
    static if(settings.imaginary){
        return Unqual!T.stringof ~ "(" ~ value.im.writefloat ~ "i)";
    }else{
        return value.im.writefloat ~ "i";
    }
}

string complextostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isComplex!T){
    string getcontent(){
        if(value.im < 0){
            return value.re.writefloat ~ value.im.writefloat ~ "i";
        }else{
            return value.re.writefloat ~ "+" ~ value.im.writefloat ~ "i";
        }
    }
    static if(settings.complex){
        return Unqual!T.stringof ~ "(" ~ getcontent() ~ ")";
    }else{
        return getcontent();
    }
}

string charactertostring(
    StrSettings settings = StrSettings.Default, bool quoteliterals = false, T
)(
    in T value
) if(isCharacter!T){
    string getcontent(){
        static if(is(Unqual!T == char)){
            return cast(string)[value];
        }else{
            return value.utf8encode.toString();
        }
    }
    static if(settings.characters){
        alias U = Unqual!T;
        static if(is(U == char)) return `'` ~ getcontent() ~ `'`;
        else static if(is(U == wchar)) return `'` ~ getcontent() ~ `'w`;
        else static if(is(U == dchar)) return `'` ~ getcontent() ~ `'d`;
        else static assert(false, "Unknown character type."); // Shouldn't happen
    }else static if(quoteliterals){
        return `'` ~ getcontent() ~ `'`;
    }else{
        return getcontent();
    }
}

string stringtostring(
    StrSettings settings = StrSettings.Default, bool quoteliterals = false, T
)(
    auto ref T value
) if(isString!T && isFiniteIterable!T){
    string getcontent(){
        string result;
        static if(hasNumericLength!T){
            result.reserve(value.length);
        }
        static if(isCharString!T){
            foreach(ch; value) result ~= ch;
        }else{
            foreach(ch; value.utf8encode) result ~= ch;
        }
        return result;
    }
    static if(settings.strings){
        string getquoted(){
            static if(isCharString!T) return `"` ~ getcontent() ~ `"`;
            else static if(isWString!T) return `"` ~ getcontent() ~ `"w`;
            else static if(isDString!T) return `"` ~ getcontent() ~ `"d`;
            else static assert(false, "Unknown string type."); // Shouldn't happen
        }
        static if(isArray!T){
            return getquoted();
        }else{
            return T.stringof ~ "." ~ getquoted();
        }
    }else static if(quoteliterals){
        return `"` ~ getcontent() ~ `"`;
    }else{
        return getcontent();
    }
}

string pointertostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isPointer!T){
    string getcontent(){
        return value is null ? "null" : "0x" ~ (cast(size_t) value).writeptr;
    }
    static if(settings.pointers){
        return PointerType!T.stringof ~ "*" ~ getcontent();
    }else{
        return getcontent();
    }
}

string enumtostring(StrSettings settings = StrSettings.Default, T)(
    in T value
) if(isEnumType!T){
    static if(settings.enums){
        return T.stringof ~ "." ~ value.enummembername;
    }else{
        return value.enummembername;
    }
}



version(unittest){
    private:
    import mach.traits : FloatTypes, IntegralTypes, isSigned;
    import mach.meta : Aliases;
    alias Verbose = StrSettings.Verbose;
}
unittest{
    assert(false.booleantostring == "false");
    assert(true.booleantostring == "true");
}
unittest{
    foreach(T; Aliases!(IntegralTypes)){
        assert(T(0).integertostring == "0");
        assert(T(1).integertostring == "1");
        assert(T(127).integertostring == "127");
        static if(isSigned!T){
            assert(T(-1).integertostring == "-1");
            assert(T(-128).integertostring == "-128");
        }
    }
    assert(int(0).integertostring!Verbose == "int(0)");
    assert(long(0).integertostring!Verbose == "long(0)");
}
unittest{
    foreach(T; Aliases!(FloatTypes)){
        assert(T(0).floattostring == "0");
        assert(T(1.5).floattostring == "1.5");
        assert(T(5.25).floattostring == "5.25");
        assert(T(-1).floattostring == "-1");
        assert((T.nan).floattostring == "nan");
        assert((T.infinity).floattostring == "inf");
        assert((-T.infinity).floattostring == "-inf");
    }
    assert(float(0).floattostring!Verbose == "float(0)");
    assert(double(0).floattostring!Verbose == "double(0)");
}
unittest{
    assert((4i).imaginarytostring == "4i");
    assert((5.25i).imaginarytostring == "5.25i");
    assert((-1i).imaginarytostring == "-1i");
    assert((1+4i).complextostring == "1+4i");
    assert((0.25+0.25i).complextostring == "0.25+0.25i");
    assert((-1-1i).complextostring == "-1-1i");
    assert(ifloat(4i).imaginarytostring!Verbose == "ifloat(4i)");
    assert(cfloat(1+4i).complextostring!Verbose == "cfloat(1+4i)");
}
unittest{
    assert(char('\0').charactertostring == "\0");
    assert(wchar('\0').charactertostring == "\0");
    assert(dchar('\0').charactertostring == "\0");
    assert(char('x').charactertostring == "x");
    assert(wchar('x').charactertostring == "x");
    assert(dchar('x').charactertostring == "x");
    assert(wchar('א').charactertostring == "א");
    assert(dchar('א').charactertostring == "א");
    assert(dchar('ツ').charactertostring == "ツ");
    assert(dchar('😃').charactertostring == "😃");
    assert(char('x').charactertostring!(StrSettings.Concise, true) == "'x'");
    assert(wchar('x').charactertostring!(StrSettings.Concise, true) == "'x'");
    assert(dchar('x').charactertostring!(StrSettings.Concise, true) == "'x'");
    assert(char('x').charactertostring!Verbose == "'x'");
    assert(wchar('x').charactertostring!Verbose == "'x'w");
    assert(dchar('x').charactertostring!Verbose == "'x'd");
}
unittest{
    assert("".stringtostring == "");
    assert("x".stringtostring == "x");
    assert("hello".stringtostring == "hello");
    assert("!אツ😃".stringtostring == "!אツ😃");
    assert(""w.stringtostring == "");
    assert("x"w.stringtostring == "x");
    assert("hello"w.stringtostring == "hello");
    //assert("!אツ😃"w.stringtostring == "!אツ😃"); // TODO: UTF-16 decoding
    assert(""d.stringtostring == "");
    assert("x"d.stringtostring == "x");
    assert("hello"d.stringtostring == "hello");
    assert("!אツ😃"d.stringtostring == "!אツ😃");
    assert("hello".stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert("hello"w.stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert("hello"d.stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert("hello".stringtostring!Verbose == `"hello"`);
    assert("hello"w.stringtostring!Verbose == `"hello"w`);
    assert("hello"d.stringtostring!Verbose == `"hello"d`);
}
unittest{
    struct StringRange(Char){
        immutable(Char)[] basis; size_t index = 0;
        @property bool empty() const{return this.index >= this.basis.length;}
        @property auto front() const{return this.basis[this.index];}
        void popFront(){this.index++;}
    }
    assert(StringRange!char("").stringtostring == "");
    assert(StringRange!wchar("").stringtostring == "");
    assert(StringRange!dchar("").stringtostring == "");
    assert(StringRange!char("hello").stringtostring == "hello");
    assert(StringRange!wchar("hello").stringtostring == "hello");
    assert(StringRange!dchar("hello").stringtostring == "hello");
    assert(StringRange!char("hello").stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert(StringRange!wchar("hello").stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert(StringRange!dchar("hello").stringtostring!(StrSettings.Concise, true) == `"hello"`);
    assert(StringRange!char("hello").stringtostring!Verbose == `StringRange!char."hello"`);
    assert(StringRange!wchar("hello").stringtostring!Verbose == `StringRange!wchar."hello"w`);
    assert(StringRange!dchar("hello").stringtostring!Verbose == `StringRange!dchar."hello"d`);
}
unittest{
    int* a = null;
    int* b = cast(int*) 0x1;
    int* c = cast(int*) 0xABCDE;
    assert(a.pointertostring == "null");
    assert(b.pointertostring == "0x1");
    assert(c.pointertostring == "0xABCDE");
    assert(a.pointertostring!Verbose == "int*null");
    assert(b.pointertostring!Verbose == "int*0x1");
    assert(c.pointertostring!Verbose == "int*0xABCDE");
}
unittest{
    enum Hello{What, Is, Up}
    enum X{A, B, C}
    alias Y = X;
    assert(Hello.What.enumtostring == "What");
    assert(Hello.Is.enumtostring == "Is");
    assert(Hello.Up.enumtostring == "Up");
    assert(Hello.What.enumtostring!Verbose == "Hello.What");
    assert(Hello.Is.enumtostring!Verbose == "Hello.Is");
    assert(Hello.Up.enumtostring!Verbose == "Hello.Up");
    assert(X.A.enumtostring!Verbose == "X.A");
    assert(Y.A.enumtostring!Verbose == "X.A");
}
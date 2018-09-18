module mach.time.duration;

private:

import mach.traits.primitives : isNumeric, isSignedIntegral;

/++ Docs

This module implements the `Duration` type. It can be used to represent
some length of time.

It provides various properties for getting the amount of time as various
units. Note that each unit supported by `Duration` has an integral and
a fractional method, for example `duration.seconds` returns the number of
seconds as an integer, rounded down, and `duration.fseconds` returns the
number of seconds as a floating point number, including fractional seconds.

+/

unittest { /// Example
    alias LongDuration = Duration!long;
    auto duration = LongDuration.Seconds(15);
    assert(duration.seconds == 15);
    assert(duration.milliseconds == 15_000);
}

unittest { /// Example
    auto duration = Duration!long.Seconds(15);
    // Integer minutes, rounded down
    assert(duration.minutes == 0);
    // Floating point minutes, exact
    assert(duration.fminutes == 0.25);
}

public:

/// Helper to determine what type should be returned when performing
/// operations on differing Duration types, i.e. those using different
/// integer types to represent their backing values.
template CommonDurationType(AT, BT){
    static if(AT.sizeof >= BT.sizeof){
        alias CommonDurationType = AT;
    }else{
        alias CommonDurationType = BT;
    }
}

/// Represents some time duration
struct Duration (T = long) if(isSignedIntegral!T) {
    /// A Duration containing zero time
    enum typeof(this) Zero = typeof(this)(0);
    
    /// The backing time value for this duration,
    /// measured in nanoseconds
    T value;
    
    /// Initialize a Duration object with a length of N weeks
    static typeof(this) Weeks(N)(in N value) if(isNumeric!N) {
        return typeof(this).Days(value * 7L);
    }
    /// Initialize a Duration object with a length of N days
    static typeof(this) Days(N)(in N value) if(isNumeric!N) {
        return typeof(this).Hours(value * 24L);
    }
    /// Initialize a Duration object with a length of N hours
    static typeof(this) Hours(N)(in N value) if(isNumeric!N) {
        return typeof(this).Seconds(value * 3_600L);
    }
    /// Initialize a Duration object with a length of N minutes
    static typeof(this) Minutes(N)(in N value) if(isNumeric!N) {
        return typeof(this).Seconds(value * 60L);
    }
    /// Initialize a Duration object with a length of N seconds
    static typeof(this) Seconds(N)(in N value) if(isNumeric!N) {
        return typeof(this)(cast(T) (value * 1_000_000_000L));
    }
    /// Initialize a Duration object with a length of N milliseconds
    static typeof(this) Milliseconds(N)(in N value) if(isNumeric!N) {
        return typeof(this)(cast(T) (value * 1_000_000L));
    }
    /// Initialize a Duration object with a length of N microseconds
    static typeof(this) Microseconds(N)(in N value) if(isNumeric!N) {
        return typeof(this)(cast(T) (value * 1_000L));
    }
    /// Initialize a Duration object with a length of N nanoseconds
    static typeof(this) Nanoseconds(N)(in N value) if(isNumeric!N) {
        return typeof(this)(cast(T) value);
    }
    
    /// Get the number of weeks as an integer, rounded down
    @property T weeks() const{
        return this.days / T(7);
    }
    /// Get the number of weeks as a floating point number
    @property double fweeks() const{
        return this.fdays / double(7);
    }
    /// Get the number of days as an integer, rounded down
    @property T days() const{
        return this.hours / T(24);
    }
    /// Get the number of days as a floating point number
    @property double fdays() const{
        return this.fhours / double(24);
    }
    /// Get the number of hours as an integer, rounded down
    @property T hours() const{
        return this.seconds / T(3_600);
    }
    /// Get the number of hours as a floating point number
    @property double fhours() const{
        return this.fseconds / double(3_600);
    }
    /// Get the number of minutes as an integer, rounded down
    @property T minutes() const{
        return this.seconds / T(60);
    }
    /// Get the number of minutes as a floating point number
    @property double fminutes() const{
        return this.fseconds / double(60);
    }
    /// Get the number of seconds as an integer, rounded down
    @property T seconds() const{
        return this.value / T(1_000_000_000);
    }
    /// Get the number of seconds as a floating point number
    @property double fseconds() const{
        return this.value / double(1_000_000_000);
    }
    /// Get the number of milliseconds as an integer, rounded down
    @property T milliseconds() const{
        return this.value / T(1_000_000);
    }
    /// Get the number of milliseconds as a floating point number
    @property double fmilliseconds() const{
        return this.value / double(1_000_000);
    }
    /// Get the number of microseconds as an integer, rounded down
    @property T microseconds() const{
        return this.value / T(1_000);
    }
    /// Get the number of microseconds as a floating point number
    @property double fmicroseconds() const{
        return this.value / double(1_000);
    }
    /// Get the number of nanoseconds as an integer, rounded down
    @property T nanoseconds() const{
        return this.value;
    }
    /// Get the number of nanoseconds as a floating point number
    @property double fnanoseconds() const{
        return cast(double) this.value;
    }
    
    /// Cast to boolean.
    /// The empty duration is a falsey value.
    /// Nonzero durations are truthy values.
    bool opCast(T: bool)() const{
        return this.value != 0;
    }
    
    /// Get whether two durations are equivalent to one another
    bool opEquals(T)(in Duration!T other) const{
        return this.nanoseconds == other.nanoseconds;
    }
    
    /// Compare two durations to one another
    int opCmp(T)(in Duration!T other) const{
        if(this.nanoseconds > other.nanoseconds){
            return +1;
        }else if(this.nanoseconds < other.nanoseconds){
            return -1;
        }else{
            return 0;
        }
    }
    
    /// Sum two durations together
    auto opBinary(string op: "+", OT)(in Duration!OT other){
        alias Common = CommonDurationType!(T, OT);
        alias DurationOut = Duration!Common;
        const ns = cast(Common) this.nanoseconds + cast(Common) other.nanoseconds;
        return DurationOut.Nanoseconds(ns);
    }
    
    /// Subtract one duration from another
    auto opBinary(string op: "-", OT)(in Duration!OT other){
        alias Common = CommonDurationType!(T, OT);
        alias DurationOut = Duration!Common;
        const ns = cast(Common) this.nanoseconds - cast(Common) other.nanoseconds;
        return DurationOut.Nanoseconds(ns);
    }
    
    /// Multiply the value of a duration by a scalar
    auto opBinary(string op: "*", N)(in N value) if(isNumeric!N){
        return typeof(this)(this.value * value);
    }
    
    /// Divide a duration by a scalar
    auto opBinary(string op: "/", N)(in N value) if(isNumeric!N){
        return typeof(this)(this.value / value);
    }
    
    /// Divide one duration by another
    /// Returns a floating point scalar value
    double opBinary(string op: "/", OT)(in Duration!OT other){
        return cast(double) this.nanoseconds / cast(double) other.nanoseconds;
    }
    
    /// Get the modulo of two durations
    auto opBinary(string op: "%", OT)(in Duration!OT other){
        alias Common = CommonDurationType!(T, OT);
        alias DurationOut = Duration!Common;
        const ns = cast(Common) this.nanoseconds % cast(Common) other.nanoseconds;
        return DurationOut.Nanoseconds(ns);
    }
}

/// Create Duration objects
unittest {
    alias Dur = Duration!long;
    assert(Dur.Weeks(100).weeks == 100);
    assert(Dur.Days(100).days == 100);
    assert(Dur.Hours(100).hours == 100);
    assert(Dur.Minutes(100).minutes == 100);
    assert(Dur.Seconds(100).seconds == 100);
    assert(Dur.Milliseconds(100).milliseconds == 100);
    assert(Dur.Microseconds(100).microseconds == 100);
    assert(Dur.Nanoseconds(100).nanoseconds == 100);
}

/// Get fractional time values
unittest {
    alias Dur = Duration!long;
    assert(Dur.Days(3.5).fweeks == 0.5);
    assert(Dur.Hours(36).fdays == 1.5);
    assert(Dur.Minutes(75).fhours == 1.25);
    assert(Dur.Seconds(45).fminutes == 0.75);
    assert(Dur.Milliseconds(125).fseconds == 0.125);
    assert(Dur.Microseconds(62.5).fmilliseconds == 0.0625);
    assert(Dur.Nanoseconds(250).fmicroseconds == 0.25);
    assert(Dur.Nanoseconds(100).fnanoseconds == 100.0);
}

/// Negative durations
unittest {
    alias Dur = Duration!long;
    assert(Dur.Hours(-24).days == -1);
    assert(Dur.Minutes(-330).fhours == -5.5);
}

/// opCast(T: boolean)
unittest {
    assert(!Duration!long.Zero);
    assert(Duration!long.Nanoseconds(+1));
    assert(Duration!long.Nanoseconds(-1));
}

/// Duration equality
unittest {
    alias DurInt = Duration!int;
    alias DurLong = Duration!long;
    assert(DurInt.Zero == DurLong.Zero);
    assert(DurInt.Milliseconds(+20) == DurLong.Milliseconds(+20));
    assert(DurInt.Milliseconds(-20) == DurLong.Milliseconds(-20));
    assert(DurInt.Milliseconds(100) != DurLong.Milliseconds(300));
    assert(DurInt.Milliseconds(+100) != DurLong.Milliseconds(-100));
}

/// Duration comparison
unittest {
    alias DurInt = Duration!int;
    alias DurLong = Duration!long;
    assert(DurInt.Zero >= DurLong.Zero);
    assert(DurInt.Zero <= DurLong.Zero);
    assert(!(DurInt.Zero > DurLong.Zero));
    assert(!(DurInt.Zero < DurLong.Zero));
    const posInt = DurInt.Milliseconds(+10);
    const negInt = DurInt.Milliseconds(-10);
    const posLong = DurInt.Milliseconds(+10);
    const negLong = DurInt.Milliseconds(-10);
    assert(negInt < posInt);
    assert(posInt > negInt);
    assert(posInt > DurInt.Zero);
    assert(negLong < posLong);
    assert(posLong > negLong);
    assert(posLong > DurLong.Zero);
    assert(negInt < posLong);
    assert(posInt > negLong);
}

/// Binary operations (with scalar)
unittest {
    alias Dur = Duration!long;
    assert(Dur.Minutes(5) * 5 == Dur.Minutes(25));
    assert(Dur.Minutes(20) / 5 == Dur.Minutes(4));
}

/// Binary operations (same duration type)
unittest {
    alias Dur = Duration!long;
    assert(Dur.Minutes(10) + Dur.Minutes(15) == Dur.Minutes(25));
    assert(Dur.Minutes(15) - Dur.Minutes(5) == Dur.Minutes(10));
    assert(Dur.Minutes(10) / Dur.Minutes(20) == 0.5);
    assert(Dur.Minutes(20) % Dur.Minutes(15) == Dur.Minutes(5));
}

/// Binary operations (different duration type)
unittest {
    alias DurInt = Duration!int;
    alias DurLong = Duration!long;
    // Addition
    auto sum = DurInt.Milliseconds(10) + DurLong.Milliseconds(15);
    static assert(is(typeof(sum) == DurLong));
    assert(sum.milliseconds == 25);
    // Subtraction
    auto diff = DurLong.Milliseconds(10) - DurLong.Milliseconds(15);
    static assert(is(typeof(diff) == DurLong));
    assert(diff.milliseconds == -5);
    // Modulo
    auto mod = DurLong.Milliseconds(10) - DurLong.Milliseconds(15);
    static assert(is(typeof(mod) == DurLong));
    assert(mod.milliseconds == -5);
    // Division
    auto quot = DurInt.Milliseconds(15) / DurLong.Milliseconds(5);
    assert(quot == 3);
}

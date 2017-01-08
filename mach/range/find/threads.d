module mach.range.find.threads;

private:

import mach.traits : canSliceSame;
import mach.range.find.result;

public:



/// Common methods for find thread types.
template FindThreadMixin(bool forward, Index){
    auto result(bool plural = true, Iter)(Iter iter, Index index){
        static if(forward){
            immutable Index low = this.foundindex;
            immutable Index high = index + 1;
        }else{
            immutable Index low = index - 1;
            immutable Index high = this.foundindex;
        }
        static if(canSliceSame!Iter){
            auto slice = iter[low .. high];
            static if(plural){
                return FindResultPlural!(Index, typeof(slice))(low, slice);
            }else{
                return FindResultSingular!(Index, typeof(slice))(low, slice, true);
            }
        }else{
            static if(plural){
                return FindResultIndexPlural!(Index)(low);
            }else{
                return FindResultIndexSingular!(Index)(low, true);
            }
        }
    }
}

/// Contains information for an individual search thread where the subject being
/// searched for has random access.
struct FindRandomAccessThread(alias pred, bool forward, Index){
    mixin FindThreadMixin!(forward, Index);
    
    Index foundindex;
    Index searchindex;
    bool alive;
    
    this(Index foundindex, Index searchindex, bool alive = true){
        this.foundindex = foundindex;
        this.searchindex = searchindex;
        this.alive = alive;
    }
    bool next(Element, Subject)(Element element, Subject subject){
        if(pred(element, subject[this.searchindex])){
            static if(forward){
                this.searchindex++;
                if(this.searchindex >= subject.length){
                    this.alive = false;
                    return true;
                }else{
                    return false;
                }
            }else{
                if(this.searchindex == 0){
                    this.alive = false;
                    return true;
                }else{
                    this.searchindex--;
                    return false;
                }
            }
        }else{
            this.alive = false;
            return false;
        }
    }
    
    @property typeof(this) dup(){
        return typeof(this)(this.foundindex, this.searchindex, this.alive);
    }
}

/// Contains information for an individual search thread where the subject being
/// searched for is a saving range.
struct FindSavingThread(alias pred, bool forward, Index, Range){
    mixin FindThreadMixin!(forward, Index);
    
    Index foundindex;
    Range searchrange;
    bool alive;
    
    this(Index foundindex, Range searchrange, bool alive = true){
        this.foundindex = foundindex;
        this.searchrange = searchrange;
        this.alive = alive;
    }
    bool next(Element)(Element element){
        static if(forward){
            if(pred(element, this.searchrange.front)){
                this.searchrange.popFront();
                if(this.searchrange.empty){
                    this.alive = false;
                    return true;
                }else{
                    return false;
                }
            }
        }else{
            if(pred(element, this.searchrange.back)){
                this.searchrange.popBack();
                if(this.searchrange.empty){
                    this.alive = false;
                    return true;
                }else{
                    return false;
                }
            }
        }
        this.alive = false;
        return false;
    }
    
    @property typeof(this) dup(){
        return typeof(this)(this.foundindex, this.searchrange.save, this.alive);
    }
}



/// Used by find functions to collect and manage search threads.
struct FindThreadManager(Thread){
    size_t threshold;
    Thread[] threads;
    
    this(size_t threshold){
        this.threshold = threshold;
    }
    
    /// Add a new thread to the list
    void add(Thread thread){
        this.threads ~= thread;
    }
    
    /// Remove dead threads from the list
    void clean(){
        Thread[] alive;
        foreach(thread; this.threads){
            if(thread.alive) alive ~= thread;
        }
        this.threads = alive;
    }
    
    /// Iterate over alive threads
    int opApply(in int delegate(ref Thread thread) apply){
        int result = 0;
        size_t dead = 0;
        foreach(ref thread; this.threads){
            if(thread.alive){
                result = apply(thread);
                if(result) break;
                dead += !thread.alive;
            }else{
                dead++;
            }
        }
        if(!result && dead > this.threshold) this.clean();
        return result;
    }
    
    @property typeof(this) dup(){
        typeof(this) manager;
        manager.threshold = this.threshold;
        foreach(ref thread; this.threads){
            if(thread.alive) manager.threads ~= thread.dup;
        }
        return manager;
    }
}

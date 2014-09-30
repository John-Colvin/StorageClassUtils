import std.traits : ParameterTypeTuple,
       ParameterStorageClassTuple,
       STC = ParameterStorageClass;
import std.typetuple : TT = TypeTuple, Alias;

struct ScopeSC(T)
{
    @disable this();
    alias base = T;
    enum scString = "scope";
}
struct OutSC(T)
{
    @disable this();
    alias base = T;
    enum scString = "out";
}
struct RefSC(T)
{
    @disable this();
    alias base = T;
    enum scString = "ref";
}
struct LazySC(T)
{
    @disable this();
    alias base = T;
    enum scString = "lazy";
}

template isSC(T)
{
    static if(is(T : ScopeSC!X, X)
            ||is(T : OutSC!X, X)
            ||is(T : RefSC!X, X)
            ||is(T : LazySC!X, X))
        enum isSC = true;
    else
        enum isSC = false;
}
    
template StorageClassWrapper(uint stc) //for some reason STC doesn't work
{
    static if(stc == STC.none)
        alias StorageClassWrapper = Alias;
    else static if(stc == STC.scope_)
        alias StorageClassWrapper = ScopeSC;
    else static if(stc == STC.out_)
        alias StorageClassWrapper = OutSC;
    else static if(stc == STC.ref_)
        alias StorageClassWrapper = RefSC;
    else static if(stc == STC.lazy_)
        alias StorageClassWrapper = LazySC;
    else
        static assert(false, "invalid ParameterStorageClass");
}

alias SCWrappedParameterTypeTuple(alias F) =
        WrapStorageClasses!(ParameterTypeTuple!F, ParameterStorageClassTuple!F);
    
template WrapStorageClasses(TL ...)
    if(!(TL.length % 2))
{
    alias Ts = TL[0 .. $/2];
    alias SCs = TL[$/2 .. $];
    
    static if(TL.length == 0)
        alias WrapStorageClasses = TT!();
    else
    {
        alias Wrapper = StorageClassWrapper!(TL[$/2]);
        alias WrapStorageClasses = TT!(Wrapper!(TL[0]),
                WrapStorageClasses!(TT!(TL[1..$/2], TL[$/2+1 .. $])));
    }
}

unittest
{
    struct S {}
    void f(ref int a, lazy double e, S s) {}
    alias wrappedParams = 
        WrapStorageClasses!(ParameterTypeTuple!f, ParameterStorageClassTuple!f);
    static assert(is(wrappedParams == TT!(RefSC!int, LazySC!double, S)));

    static assert(is(UnwrapStorageClasses!wrappedParams == ParameterTypeTuple!f));
}

template UnwrapStorageClasses(TL ...)
{
    alias getBase(T) = T.base;
    
    static if(TL.length == 0)
        alias UnwrapStorageClasses = TT!();
    else 
    {
         mixin(
            {
                import std.conv : to;
                string s = `alias UnwrapStorageClasses = ParameterTypeTuple!((`;
                foreach(i, T; TL)
                {
                    static if(isSC!T)
                        s ~= T.scString ~ " getBase!(TL[" ~ i.to!string ~ "])";//T.base.stringof;
                    else
                        s ~= "TL[" ~ i.to!string ~ "]";//T.stringof;
                    s ~= " p" ~ i.to!string ~ ", ";
                }
                return s[0..$-2] ~ `){});`;
            }());
    }
}

unittest
{    
    struct S(TL ...)
    {
        void f(UnwrapStorageClasses!TL p){}
    }
    
    S!() s0;
    static assert(ParameterStorageClassTuple!(s0.f).length == 0);

    struct FD {}

    S!(RefSC!int, float, FD) s1;

    static assert(ParameterStorageClassTuple!(s1.f) ==
            TT!(STC.ref_, STC.none, STC.none));


    S!(RefSC!int, float, ScopeSC!FD) s2;

    static assert(ParameterStorageClassTuple!(s2.f) ==
            TT!(STC.ref_, STC.none, STC.scope_));
}

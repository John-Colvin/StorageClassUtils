StorageClassUtils
=================

Storage classes are irritating to work with in D. This might help.

Use it like this:
```D
void f(ref int a, lazy double e, S s) {}
alias wrappedParams = SCWrappedParameterTypeTuple!f;

// pass around and manipulate that parameter list however you like,
// the storage classes aren't going anywhere.

//fish out the base type from a wrapped param
alias secondArgsT = wrappedParams[1].base;

// to get the unwrapped list back again:
alias unwrapped = UnwrapStorageClasses!(wrappedParams);
// which should be identical to what you would get from
// std.traits.ParameterTypeTuple
```

A use case:
```D
struct S(TL ...)
{
    void f(UnwrapStorageClasses!TL p){}
}

S!(RefSC!int, float, ScopeSC!FD) s;

//s.f takes parameters (ref int, float, scope FD)
```

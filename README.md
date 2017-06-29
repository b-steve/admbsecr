# admbsecr

**The admbsecr package is now deprecated.** It has been replaced by the [ascr](https://github.com/b-steve/ascr/) package; admbsecr version 1.2.3 is virtually identical to ascr version 2.0.0, but the latter

1. Has slightly improved documentation,

2. Has a better name,

3. Has a few differently named functions to reflect this:
    * The function `fit.ascr()` replaces `admbsecr()`
    * The function `boot.ascr()` replaces `boot.admbsecr()`
    * The function `test.ascr()` replaces `test.admbsecr()`

However, all existing code that made use of the admbsecr package **should still run cleanly using ascr.** That is, using `admbsecr()` and above friends should still work just fine.
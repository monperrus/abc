# ZM~~ # PRinty# C with ABC!

"C with ABC!" is a [SIGBOVIK 2017](https://sigbovik.org/2017/) paper by Tom7, see reference website at <http://tom7.org/abc/>.

Well it's not only a paper, it's also a program called `paper.exe`. `paper.exe` is a music synthesizer for DOS, playing music given in [ABC notation](https://en.wikipedia.org/wiki/ABC_notation). It uses a special x86 instruction subset, see [the paper](http://tom7.org/abc/).

`paper.exe` is compiled from `paper.c` with `abc.exe` which is a C compiler written in standard ML.

The whole project can be see as a sophisticated art installation. It is known that computer art, esp. based on program execution, tends to rot very quickly, because of the ever changing hardware and software stack. 

In March 2024, I succeeded to run the installation again after fixing a few things. For this, I'm running Linux (Ubuntu 22, 5.15.0), on a x86_64 processor.


This repo documents this reproduction and contributes to the long term preservation of the art piece.

## Background

The code is available at http://sourceforge.net/p/tom7misc/svn/HEAD/tree/trunk/abc/. The SVN history has been ported here..

The whole project is mostly standard ML, compiled with [mlton](https://github.com/MLton/mlton/).
I downloaded the latest release 20210107 (Jan 7 2022) from the [Github release page](https://github.com/MLton/mlton/releases).
I chose the binary format with `mlton-20210117-1.amd64-linux-glibc2.23.tgz` 

abc depends on Tom7's own library sml-lib also available in SVN. 

abc builds with make.

## Breakages

An initial run gives this error trace: https://gist.github.com/monperrus/1b26d4ecd52ddddf475d681b60712499

The breakage is due to the following non-backward changes:

- MLton changed the type of global variable `MLton.size` and the definition of `PP_DEVICE` in `pp-device-sig.ml`.
- Linux linker `ld` changed default behavior related to [Position Independent Executables (PIE)](https://www.redhat.com/en/blog/position-independent-executables-pie).

## Fixes

### makefile

The first easy fix is to change `makefile` with your own mlton path

```
MLTON=/tmp/mlton-20210117-1.amd64-linux-glibc2.23/bin/mlton
```

### MLton

The ML fixes are spread in the code of abc (`abc/ckit/parser/util/old-pp.sml`) and the mlton main directory itself, in particular in `lib/mlton/sml/smlnj-lib/PP/src/pp-device-sig.sml`

See https://github.com/monperrus/abc/commit/9003db6cf8b1281cd8a33ba8e49a4c97587446c4 and https://github.com/monperrus/abc/commit/97158c5d2809f465e142876e8fc7bee3cd2cd171.

### Linker ld

The next error is 

```
/tmp/mlton-20210117-1.amd64-linux-glibc2.23/bin/mlton -output benchbytes.exe benchbytes.mlb
/bin/ld: /tmp/filevbf1Zq.o: relocation R_X86_64_32S against hidden symbol `staticHeapI' can not be used when making a PIE object
/bin/ld: failed to set dynamic section sizes: bad value
collect2: error: ld returned 1 exit status
MLton 20210117 raised: Fail: call to system failed with Fail: exit status 1:
cc -o benchbytes.exe /tmp/fileRCxE39.o /tmp/filevbf1Zq.o -L/tmp/mlton-20210117-1.amd64-linux-glibc2.23/lib/mlton/targets/self -lmlton -lgdtoa -lm -lgmp -m64 -Wl,-znoexecstack
make: *** [makefile:31: benchbytes.exe] Error 1
```

The fix is to add `-link-opt -no-pie` to all calls in makefile, see https://github.com/monperrus/abc/commit/9003db6cf8b1281cd8a33ba8e49a4c97587446c4.

## Outcome

Now you can build abc.exe, benchbytes.exe, histo.exe, historec.exe, makefreq.exe	midi2abc.exe, png2ascii.exe	text2pdf.exe, twocolumn.exe from Standard ML

And then one can build paper.exe from paper.c.

And finally one can run paper.exe with dosbox (the normal one available on my distribution, not the modified one in the repo, see paper for details).

```
$ dosbox paper.exe
```


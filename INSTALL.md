# Installation instructions

Get the troff2page from GitHub:

```
git clone https://github.com/ds26gte/troff2page
```

This creates a directory `troff2page`.  `cd` to it.

Copy the script `troff2page` to a directory in your PATH.

Copy the files

```
tmac/defhsl.tmac
tmac/eval4troff.tmac
tmac/htmlindex.tmac
tmac/index.tmac
tmac/t2pslides.tmac
tmac/url.tmac
```

to a directory in your GROFF_TMAC_PATH, or your home directory.

Copy the file `man/man1/troff2page.1` to the `man1` subdirectory of a
directory in your MANPATH.

Copy the file `man/man7/eval4troff.tmac.7` to the `man7` subdirectory of a
directory in your MANPATH.

## Man pages

You can now consult the man pages troff2page(1) and eval4troff.tmac(7)
to get started with using troff2page.

## Lisp implementions

The script `troff2page` uses the Common Lisp implementation mentioned by the shell
environment variable LISP.  Currently, the values supported for LISP
are:

```
clisp
clozure
cmu
ecl
sbcl
```

If LISP is not set, some default implementation is assumed.
Here are some ways to invoke troff2page (assume LISP
unset):

```
% troff2page jobname.ms    # uses some default Lisp impl

% LISP=clozure troff2page jobname.ms  # uses Clozure

% export LISP=sbcl         # uses SBCL henceforth
% troff2page jobname.ms
```

To have troff2page run on Common Lisp implementations other than these,
you will have to add lines to the head of the `troff2page` file.

To have `.eval` work for groff (and not just troff2page), you will have to
add lines in the corresponding area in the file `eval4troff.tmac` as well.

## Documentation

The file `index.ms` provides complete documentation for troff2page
and can be processed with either groff or troff2page.  To process
`index.ms`, you must have installed troff2page, including the macro
files that come with this distribution, as described above.

You will need to run groff or troff2page more than once in order to
pick up all the auxiliary file info.  Both programs will give out
information on the console telling you when you need to re-run them and
how.  Follow that information.

## Running troff2page as a Lisp procedure

It is not necessary to use the file troff2page as a Unix script.  You
can simply load `troff2page` (which is really a Lisp file) into your
Common Lisp, and then call the Lisp procedure
`troff2page:troff2page`
(i.e., the procedure named `troff2page` in the package
`troff2page`) on your
source document.  E.g.,

```
(load "pathname/of/troff2page")
(troff2page:troff2page "my-troff-document.1")
```

The procedure `troff2page:troff2page` can be called several times, on the
same or different documents, from within the same Lisp session.
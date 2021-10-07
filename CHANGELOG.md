# Changes

## v0.1.0

This is the first official release of the `mg.sh` library. This release comes as
a single file, ready for sourcing into existing projects. This file will contain
all the modules at the time of the release, in dependency order. The current set
of modules is:

+ `bootstrap` is meant to be sourced directly from the top of your script.
  Access to the other modules should happen through calling the `module`
  function. Note: qthis distinction is only meaningful when using the library as
  a submodule, as when using a released version all modules are automatically
  packed.
+ `controls` implements new program flow controls.
+ `date` provides date and time-period helpers.
+ `filesystem` provides additional file and directory helpers
+ `interaction` provides function to interact with the user at the prompt
+ `locals` provides implementation of local variables in all known shells
+ `log` provides logging utilities
+ `options` is a modern options parser
+ `portability` provides pure-shell replacements for GNU or Linux specific
  features.
+ `text` provides text-oriented utility functions.


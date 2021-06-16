# Functors

This directory contains a main script `mg.sh`. The script includes all modules
of the `mg.sh` library and is meant to be symbolic linked to. For each symbolic
link to the script, if a function exists with the same name, it will be called
with all arguments to the script as its arguments. In other words, the content
of this directory works more or less similarily to `busybox`.

# Developer Notes

## Hooks

This projects only uses pure semantic version numbers for releasing. Git [hooks]
are available to enforce this rule. Provided you do not have any hooks setup
yourself, running the following command once will ensure proper behaviour from
now on.

```console
git config --local core.hooksPath .githooks
```

  [hooks]: http://git-scm.com/docs/githooks

## Release Process

To make a release:

1. decide upon a name that will start with the letter `v` and a semantic
   version, e.g. `v0.2.3`.
2. Add a section to the [CHANGELOG](./CHANGELOG.md), second-level of heading
   with the same name as the release name, e.g. `## v0.2.3`.
3. Create a git tag with the same name.
4. Push the tag, e.g. `git push --tags`.

The release workflow should automatically generate a GitHub release with this
information.

## Shebang

This library targets most existing POSIX compatible environments. It uses the
following shebang throughout, as it is the one that seems to be the most
compatible one.

```shell
#!/bin/sh
```

This shebang, directly accessing `sh`, will work:

+ In regular distributions: tested `ubuntu`, `fedora`, `archlinux` and `gentoo`
  (`uclibc`) via their containers.
+ In slimmed downed distributions: tested `alpine` via its container.
+ In busybox-like environments: tested `busybox` and `toybox` via their
  containers.

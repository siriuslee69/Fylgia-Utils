# Fylgia Utils

This repo is meant to be a collection of some code I often use and want to have access to.

It also contains reusable parsers and small query helpers that are intended to
be shared across other repos instead of being reimplemented locally. The first
one is the boolean text-query parser under
`src/fylgia_utils/level1/text_query/`, which accepts queries such as:

```text
invoice AND 2025 AND NOT draft
("project alpha" AND notes) OR archive
```

The matcher is substring-based by default and is meant for lightweight path,
tag, and search filtering.

## Layout

Each proc has its tests written right below them. 

To test everything, first, go into a folder of your choice, make sure you have git installed and:

```bash
git clone https://github.com/siriuslee69/Fylgia-Utils
```

Then inside this directory you can call the tests in different ways.
You can run all tests at once via nimble:

```bash
nimble test all
```
or just

```bash
nimble test 
```
To test only a single file via nimble, you can use:

```bash
nimble test filename 
```
- no .nim ending or relative path needed.

If you don't want to use nimble for whatever reason, you can just provide the flags manually:


```bash
nim c -d:test -r fylgia_utils.nim
```
- tests everything.

```bash
nim c -d:test -r fileName.nim
```

- tests only one file (you have to switch into its directory first though).

## Warning

Use at your own risk. Subject to change. 

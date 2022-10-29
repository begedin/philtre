# Changelog

# 0.12.2

- [CHORE] Update mix dependencies
  - credo 1.6.0 -> 1.6.7
  - dialyxir 1.1.0 -> 1.2.0
  - ex_doc 0.28.0 -> 0.29
  - floki 0.30 -> 0.33
  - jason 1.3.0 -> 1.4.0
  - phoenix_live_view 0.17.0 -> 0.18.3
  - phoenix 1.6.0 -> 1.6.15
- [CHORE] Add and apply heex formatter
- [CHORE] Fix warnings emitted by new phoenix_live_view
- [CHORE] Update npm dependencies
  - @typescript-eslint/eslint-plugin 5.21.0 -> 5.41.0
  - cypress 9.6.0 -> 9.7.0
  - cypress-real-events 1.7.1. -> 1.7.2
  - esbuild 0.14.38 -> 0.15.12
  - eslint-plugin-prettier 4.0.0 -> 4.2.1
  - phoenix 1.6.7 -> 1.6.15
  - prismjs 1.28.0 -> 1.29.0
  - typescript 4.6.3 -> 4.8.4

# 0.12.1

- [FIX] Publish JS
- [DOCS] Add publishing instructions

Previous version didn't incoude prebuilt js and types

# 0.12.0

- [REWRITE] More agnostic block system where the ContentEditable is a base
  block through which other blocks communicate
- [FEATURE] Basic implementation for a list - not release-ready yet
- [FEATURE] Include library version in every editor

## 0.11.1

- [FEATURE] Add Javascript support for code block
- [FIX] Remove block functionatliy not actually being saved unless there is a
  manual update to another block
- [FIX] Move and rename `mix convert` -> `mix philtre.convert`

## 0.11.0

- [FEATURE] New, more general block json format

### Notes

A new format a block serializes into has been introduced. It's description is
available in the docs, unter the **outline** section.

A task to convert from old format into new is also available. You can use it by
running

```
mix philtre.convert path_where_your_files_are
```

If you need to manually convert, it should also be quite straightforward, from
looking at the documentation.

The reason for the new format is to support more generalized block structures
in the future.

## 0.10.2

- [QA] Simplify Playground endpoint
- [QA] Reorganize e2e tests around scopes
- [REFACTOR] Introduce common LiveBlock component
- [REFACTOR] Introduce common StaticBlock component
- [FIX] Transform being applied to soon due to placeholder space character in new cells
- [QA] Add blank `.credo.exs`
- [REFACTOR] Make ContentEditable less hacky
- [QA] Document ContentEditable

## 0.10.1

- [FIX] Adding a new empty h1, h2, h3, or li would crash
- [FIX] Better padding on li block
- [FEATURE] Shift + enter in /code block starts new block below
- [FEATURE] Code block auto-focuses when added
- [FEATURE] Navigation between blocks using tab and shift + tab
- [QA] Remove pageModel from integration tests
- [DOCS] Proposal for extensible block interface

## 0.10.0

- [FEATURE] Basic code block only supporing elixir synthax highlighting
- [FIX] Using button to add block after a code or table block fails
- [QA] Improve docs
- [FIX] Styles for `/code` block were not getting included correctly

## 0.9.4 2022-05-30

- [FIX] Bug with typing after inserting new line at the end of block
- [CHORE] Loosen floki dependency & update
- [CHORE] Update phoenix_live_view dependency
- [TWEAK] Use `n` to split lines in block component, instead of `<br/>`
- [TWEAK] Clean up redundant cells during block operations

## 0.9.3 2022-05-25

- fix publish + installation story

## 0.9.2 2022-05-22

- separate out scss into individual files
- style and restructure table component
- publish to hex and npm
- add basic setup readme

## 0.9.0 2022-05-21

- basic table component

## 0.8.1 2022-05-12

- various bugfixes related to blocks splitting and joining
- phoenix dependency update
- failed attempt configuration for heex formatter
- basic styling for PRE block

## 0.8.0 2022-05-08

There have been many changes since the last update

- complete engine rewrite
- e2e test suite
- conversion to library
- support for scss
- various misc additions and tweaks

## 0.7.1 2022-01-25

- reduce blocks after backspacing or updating, so they contain a minimal amount of cells

## 0.7.0 2022-01-25

- blockquote
- further codebase simplication
- removal of page struct
- bugfixes to backspace operation

## 0.6.1 2022-01-19

- simplification and improvements to internal API
- fix for a selection bug

## 0.6.0 2022-01-16

- introduce esbuild via npm
- introduce eslint
- introduce prettier
- make topbar an npm dependency

## 0.5.2 2022-01-08

- update elixir to 1.13.1 + all dependencies
- clear up credo issues
- add CI action workflow
- documentation improvements

## 0.5.0 2022-01-08

- block selection feature
- copy paste feature
- cleanup
- known bug: typing too quickly changes cursor position

## 0.4.0 2021-11-21

- block + cell based editor, supporting following blocks
  - p
  - h1,h2,h3
  - ul
  - with block downgrades, splitting, etc.

## 0.2.0 2021-11-07

- credo + pre-commit hook for credo
- dialyzer + specs + fixes + pre-commit hook for dialyzer

## 0.2.0 2021-11-06

- basic markdown support

## 0.1.0

- Basic article crud and routes
- Slug generation and uniqueness

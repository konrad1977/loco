
!["Logo"](https://github.com/konrad1977/loco/blob/main/images/logo.png)
![](https://img.shields.io/github/languages/top/konrad1977/loco)

# Loco
Loco is a extremly fast CLI linter for Localization.strings and swift files.

### What does it check?
- Untranslated strings in your swift files
- Missing keys in one or more languages
- Duplicate keys
- Unused keys
- Missing a translation file for a whole language

#### Output format
- Loco will output its result in a compiler error log format so it can easily be integrated in third party apps (like Emacs, VI)

##### Limitation
- Quick and dirty (alot of imperative coding mixed with tons of functional. Sorry purists)
- Does not lint Localization.dict
- Does not lint Storyboards
- Will have false positive and its untested

#### Installation
Compile the project using terminal (or Xcode)
```shell
swift build
```
Copy the loco binary from *.build/debug* to */usr/local/bin/*

## How to use
Just run loco from your project root.
```shell
$ loco
```

!["Example"](https://github.com/konrad1977/loco/blob/main/images/example.png)


!["Logo"](https://github.com/konrad1977/loco/blob/main/images/logo.png)
![](https://img.shields.io/github/languages/top/konrad1977/loco)

# Loco
Loco is a extremly fast CLI linter for Localization.strings and swift files.

### What does it check?
- Untranslated strings in your swift files
- Empty values
- Duplicate keys
- Unused keys
- Missing keys in one or more languages
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

## Arguments
Lint individual swift files (check for missing translations only)
```shell
$ loco -f "/myProject/Sources/Subfolder/somefile.swift"
```

## Integrate with Xcode
!["Xcode"](https://github.com/konrad1977/loco/blob/main/images/xcode.png)

In build phases. Add run script (+)
```shell
if which loco > /dev/null; then
	loco --no-color
else 
	echo "warning: Loco is not installed. Compile from https://github.com/konrad1977/loco"
fi
```
!["XcodeSetup"](https://github.com/konrad1977/loco/blob/main/images/xcode-setup.png)

Disable colored output
```shell
$ loco --no-color
```

!["Example"](https://github.com/konrad1977/loco/blob/main/images/example.png)
!["Example2"](https://github.com/konrad1977/loco/blob/main/images/example2.png)

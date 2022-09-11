
!["Logo"](https://github.com/konrad1977/loco/blob/main/images/logo.png)
![](https://img.shields.io/github/languages/top/konrad1977/loco)

# Loco
Loco is an extremly fast CLI linter for Localization.strings and swift files.

### What does it check?
- Semicolons
- *Untranslated* strings in your swift files
- Empty values
- Duplicate keys
- Unused keys
- Missing keys in one or more languages
- Missing a translation file for a whole language

#### Output format
- Loco will output its result in a compiler error log format so it can easily be integrated in third party apps (like Xcode, Emacs, Vim)

##### Limitation
- Loco builds two separate sets of data for each source file, one is for known localization pattern, such as NSLocalizedString, etc. The other one is for all the strings. Loco will then check if any of those are in a .strings file for silent warnings about unused translation keys. But it wont discover if a such key is untranslated. 
- Does not lint Localization.dict
- Does not lint Storyboards
- Will have false positive / true negatives
- Needs a bit code clean up. (imperative coding mixed with tons of functional. Sorry purists)
- Only some unit tests (more will come)

#### Installation
Compile the project using terminal (or Xcode)

##### Release
```shell
swift build -c release
```

##### Debug
```shell
swift build
```

Copy the loco binary from either .build/release or .build/debug to
```shell
/usr/local/bin
```

## How to use

### Integrate with Xcode
!["Xcode"](https://github.com/konrad1977/loco/blob/main/images/xcode.png)

In build phases. Add run script (+)
```shell
if which loco > /dev/null; then
	loco
else 
	echo "warning: Loco is not installed. Compile from https://github.com/konrad1977/loco"
fi
```
!["XcodeSetup"](https://github.com/konrad1977/loco/blob/main/images/xcode-setup.png)

*Make sure you run loco before compile sources to get info where you are missing a semicolon*

### From terminal
Just run loco from your project root.
```shell
$ loco
```

#### Arguments
Lint individual swift files (check for missing translations only)
```shell
$ loco -f "/myProject/Sources/Subfolder/somefile.swift"
```

Enable colored output
```shell
$ loco --color
```

!["Example"](https://github.com/konrad1977/loco/blob/main/images/example.png)
!["Example2"](https://github.com/konrad1977/loco/blob/main/images/example2.png)

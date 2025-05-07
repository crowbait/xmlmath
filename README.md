# XMLMath <!-- omit in toc -->

<div style="text-align: center;">
  <a href="https://github.com/crowbait/xmlmath/releases/latest">
    <img src="https://img.shields.io/github/v/release/crowbait/xmlmath" alt="Latest Release">
  </a>
  <a href="https://github.com/crowbait/xmlmath/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/crowbait/xmlmath" alt="License">
  </a>
  <a href="https://github.com/crowbait/xmlmath/actions/workflows/test.yml">
    <img src="https://github.com/crowbait/xmlmath/actions/workflows/test.yml/badge.svg" alt="Tests">
  </a>
</div>

**XMLMath** is a command-line tool for performing arithmetic operations directly on XML files.
It allows batch modifications of attributes and values using a flexible set of filters and modifiers, allowing automated XML numeric data transformations.

### Features <!-- omit in toc -->
- Run arbitrary (*awk*-compatible) mathematic operations on attribute or element values
- Target elements or attributes via tag names, or additional regex
- Clamp and/or round results
- Modify files in-place or output changes to stdout
- Optionally diff changes to stdout or a file
- Small [dependency footprint](#requirements)

#### What this is not
- Fast. It really isn't.
- Suitable for non-math operations. You'll be better of with regex-based find-replace in any text editor.

## Contents <!-- omit in toc -->
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Download](#download)
- [Usage](#usage)
  - [Examples](#examples)
  - [Operations](#operations)
  - [Options](#options)
- [Development](#development)


## Getting Started
### Requirements
**XMLMath** relies on *awk*, *sed*, *diff* and *xmllint*.
With the exception of *xmllint*, these are already included in many distributions.
On *Debian*-/*Ubuntu*-based distros, *xmllint* can be installed with:
```bash
sudo apt install libxml2-utils
```

### Download
Download the latest built version of **XMLMath** from the latest release.
You could put it somewhere that's in your PATH to make it available globally.
```bash
curl -L -o xmlmath https://github.com/crowbait/xmlmath/releases/latest/download/xmlmath
chmod +x xmlmath
```
You can also run it directly; this ensures you're always working with the latest release and doesn't put the script file on your drive.
```bash
curl -sL https://github.com/crowbait/xmlmath/releases/latest/download/xmlmath | /
bash -s -- "parameter1" "parameter2" "..."
```
You'll need to supply all parameters in quotes.

## Usage
Syntax:
```bash
./xmlmath <attr|value> <operation> <modifier> [options] <...targets>
```

### Examples
This multiplies the value (between tags) of all XML elements named "someval" *or* "otherval" in `input.xml` by 2, writing the results back to the same file:
```bash
./xmlmath value multiply 2 --file input.xml --inplace someval otherval
```
This multiplies the value all attributes in the file `in.xml` with names matching the regex `.*someattr` AND which are attributes of a tag "tagname" by 1.1, rounding the results to the neares integer and ensuring they are always greater than or equal to 2:
```bash
./xmlmath attr multiply 1.1 --int --min 2 --file in.xml --regex -w tagname '.*someattr'
```
You can run arbitrary operations on the found values, providing they can be expressed in *awk*-compatible syntax - in this case, all attribute values (see regex) will be replaced with their root added to their squared value.
**The token `x` will be substituted for the found value**:
```bash
./xmlmath attr expression 'sqrt(x)+x*x' --file in.xml -r '.*'
```
You can get more examples from the tests: `test.sh` list commands.
The index names of those commands correspond to files in `test/`, which contain the transformed output when running these commands on `test/_expectation-template.xml`.

### Operations
The following operations are available:
- `add` or `a`: add the modifier to the found values
- `subtract` or `s`: subtract the modifier from the found values
- `multiply` or `m`: multiply the found values with the modifier
- `divide` or `d`: divide the found values by the modifier
- `set`: set the value to the modifier
- `expression` or `e` treats the modifier as an expression. It must be *awk*-compatible syntax and should be (single-)quoted.

### Options
| **Option**                                 | **Short** | **Arg** | **Description**                                                                                                                                        |
| ------------------------------------------ | --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **--file**                                 | -f        | Path    | Specifies a file to be used as input. If not given, input is taken from stdin.                                                                         |
| *requires `-f`*<br>**--inplace**           | -p        |         | Writes the output back to the same file used as input.                                                                                                 |
| **--int**                                  | -i        |         | Rounds results to the nearest integer.                                                                                                                 |
| **--min**                                  |           | Number  | Clamps all operation results to a minimum value of *Number*.                                                                                           |
| **--max**                                  |           | Number  | Clamps all operation results to a maximum value of *Number*.                                                                                           |
| **--regex**                                | -r        |         | Treats all targets (the list of attribute or value identifiers) as regex patterns instead of exact matches. You should quote each entry; see examples. |
| **--within**                               | -w        | Tag     | For *attr*: only matches attributes within the tag *Tag*.<br>For *val*: only matches values that are a child element of *Tag* - within any depth.      |
| *requires `-w`*<br>**--within-additional** | --wa      | Regex   | Only accepts a match on `--within`, if that line (containing the tag) also satisfies *Regex*.                                                          |
| **--diff**                                 | -d        |         | Displays changes after all operations have finished.                                                                                                   |
| *requires `-d`*<br>**--diff-line-length**  | --dl      | Number  | Limits the length of lines in `--diff`'s output to *Number*, truncating as needed.                                                                     |
| *requires `-d`*<br>**--diff-file**         | --df      | Path    | Writes diff to a file instead of stdout.                                                                                                               |
| **--verbose**                              | -v        |         | Prints detailed information about what's happening. **This WILL make your stdout unusable as XML.**                                                    |
| **--progress**                             |           |         | Prints progress information. Prints to stderr, so the stdout *should* not be affected. **Cannot be used with `-v`.**                                   |

## Development
The main script is modularized and `source`s its modules, which are in `parts/*`.
This is done for maintainability and is mostly personal preference.
It can be run directly in its development form or can be "compiled" by injecting the external modules into the script.
This is done by `build.sh` and writes a complete, self-contained file to `build/xmlmath`.

Testing is done using `test.sh`.
Within that script, there is an array, mapping a "test-id" to a command to run against the main script.
The input for that test run is the file `test/test.xml`, which is intentionally ill-formatted.
There must be a file `test/[test-id].xml`, which represents the expected output of the run.
New test-target-XMLs should be created from `test/_expectation-template.xml` (same content as `test.xml`, but well formatted).
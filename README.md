# SnapshotFailLocator

For when Snapshot fails, and you're too lazy to search for the test failure images.

### Requirements

Xcode 9.2 w/ Swift 4 or later.

### Running

Run on the command line:

```
$ swift run
```

### Usage

The program searches at the temporary files from all simulator devices for 'failed_*.png' files, and lists them sorted by most recently changed.

Selecting a file from the list by index opens Finder with the file selected.

Specifying an index after an equals sign, e.g. `=2`, switches the page displayed, in case more than 30 results are found.

##### Quitting

Enter an empty string or `0` to quit.
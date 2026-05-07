# Hop Hop

<img src="./images/logo.svg" width="200px"></img>

_🕵️‍♂️ Hop hop gadget scripts!_

This stupid script is used to make easier, for me, to run the scripts I have in my code folder. So, instead of going into my folders, I can configure _Hop Hop_ as a quick way to access them from anywhere in my system.

For example, I have a folder with many scripts

```
scripts/
    ├── script1.py
    ├── script2.py
    /utils
        ├── dothat.py
        ├── dothis.py
```

With Hop Hop, I can run these commands with:

```bash
hophop script1  # or hh script1
```

Or, if they are nested,

```bash
hophop utils.dothat  # or hh utils.dothat
```

## Features

At the moment, _Hop Hop_ can run `.sh`, `.py`, `.janet`, `.exs` and executable files. I may add support for other scripts in the future.

## How to install

I assume that you have installed [Janet](https://janet-lang.org) and `jpm` on your system. Then, you can just clone this repository and run:

```bash
jpm install
```

Then, you have to set up the environment variable `HOP_HOP_DIR` to point to the folder where you have your scripts. For example, if you have a folder called `scripts` in your home directory, you can set this line in your `.bashrc` or `.zshrc` file (or whatever):

```bash
HOP_HOP_DIR=~/scripts
```

After that, just _hop-hop_ around.

## How to use

Now you can just run `hophop foo.bar.baz` to run the script in `$HOP_HOP_DIR/foo/bar/baz.py` (for example).

To be even faster, you can alias `hophop` to `hh` (like I do).

You can use `hophop list` to see all available commands.

You can also print plain command names, which is useful for scripts and shell completion:

```bash
hophop list --plain
```

### Command Descriptions

If you are like me, and you always forget which command does what, you can add optional descriptions to commands:

```bash
hophop describe foo.bar.baz "Run the baz helper"
```

Descriptions are stored in `$HOP_HOP_DIR/.hophop.meta` and are shown by `hophop list`:

```bash
hophop list
```

```text
Available commands:
foo.bar.baz  Run the baz helper
```

## Shell completion

Hop Hop can generate zsh completion:

```bash
hophop completion zsh > ~/.zsh/completions/_hophop
```

Make sure the completion directory is in your `fpath` before `compinit` runs in your `.zshrc`:

```bash
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
compinit
```

## It may be that...

Yes. The name comes from what _Inspector Gadget_ say before using one of his gadgets. Or at least what it said in the Italian version.

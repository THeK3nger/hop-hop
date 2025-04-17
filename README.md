# Hop Hop 

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

## How to install

First, let's be sure we have all the dependencies.

```bash
jpm install path
jpm install sh
```

## How to use

Set up the environment variable `HOP_HOP_PATH` to point to the folder where you have your scripts. For example, if you have a folder called `scripts` in your home directory, you can set this line in your `.bashrc` or `.zshrc` file (or whatever):

```bash
HOP_HOP_PATH=~/scripts
```

After that, just _hop-hop_ around.

## It may be that... 

Yes. The name comes from what _Inspector Gadget_ say before using one of his gadgets. Or at least what it said in the Italian version.

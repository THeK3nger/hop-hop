(import path)

(def metadata-file-name ".hophop.meta")

(defn get-command-type
  "Check if the given base script name is one of the supported types."
  [base]
  (cond
    (not (nil? (os/stat (string base ".sh")))) :sh
    (not (nil? (os/stat (string base ".py")))) :py
    (not (nil? (os/stat (string base ".janet")))) :janet
    (not (nil? (os/stat (string base ".exs")))) :elixir
    :exe))

(defn command-to-path
  "Convert a command string like `foo.bar.baz` into a path `foo/bar/baz`"
  [command]
  (def splitted (string/split "." command))
  (def hophoppath (os/getenv "HOP_HOP_DIR"))
  (let [base (path/join hophoppath ;splitted)]
    (def t (get-command-type base))
    (case t
      :sh (string base ".sh")
      :py (string base ".py")
      :janet (string base ".janet")
      :elixir (string base ".exs")
      :exe base)))

(defn run-command
  "Run the command. If command is `foo.bar` it will look into `/foo/bar` in
  HOP_HOP_DIR and run it."
  [command args]

  ##(printf "Running command: %s with args %j\n" command args)
  (let [command-path (command-to-path command)]
    (cond
      (string/has-suffix? ".sh" command-path) (os/execute @["bash" command-path ;args] :p)
      (string/has-suffix? ".py" command-path) (os/execute @["python3" command-path ;args] :p)
      (string/has-suffix? ".janet" command-path) (os/execute @["janet" command-path ;args] :p)
      (string/has-suffix? ".exs" command-path) (os/execute @["elixir" command-path ;args] :p)
      (os/execute @[command-path ;args] :p))))

(defn is-directory? [path]
  (= :directory (get (os/stat path) :mode)))

(def command-suffixes @[".sh" ".py" ".janet" ".exs"])

## METADATA SECTION
## ----------------------------------------------------------------------------

(defn metadata-file?
  "Check if a file is Hop Hop metadata."
  [file]
  (= metadata-file-name file))

(defn metadata-path
  "Return the Hop Hop metadata file path."
  []
  (path/join (os/getenv "HOP_HOP_DIR") metadata-file-name))

(defn meta-escape
  "Escape a string for the Hop Hop metadata format."
  [str]
  (def buf @"")
  (each c str
    (case c
      10 (buffer/push-string buf "\\n")
      9 (buffer/push-string buf "\\t")
      92 (buffer/push-string buf "\\\\")
      (buffer/push-byte buf c)))
  (string buf))

(defn meta-unescape
  "Unescape a string from the Hop Hop metadata format."
  [str]
  (def buf @"")
  (var escaped false)
  (each c str
    (if escaped
      (do
        (case c
          110 (buffer/push-byte buf 10)
          116 (buffer/push-byte buf 9)
          92 (buffer/push-byte buf 92)
          (do
            (buffer/push-byte buf 92)
            (buffer/push-byte buf c)))
        (set escaped false))
      (if (= c 92)
        (set escaped true)
        (buffer/push-byte buf c))))
  (when escaped
    (buffer/push-byte buf 92))
  (string buf))

(defn parse-description-record
  "Parse one metadata record, returning a command-description pair or nil."
  [line]
  (def separator (string/find "\t" line))
  (when separator
    @[(meta-unescape (string/slice line 0 separator))
      (meta-unescape (string/slice line (inc separator)))]))

(defn read-command-descriptions
  "Read command descriptions from HOP_HOP_DIR metadata."
  []
  (def descriptions @{})
  (def file (metadata-path))
  (when (not (nil? (os/stat file)))
    (each raw-line (string/split "\n" (slurp file))
      (def line (string/trim raw-line))
      (when (not= "" line)
        (def record (parse-description-record line))
        (when record
          (put descriptions (get record 0) (get record 1))))))
  descriptions)

(defn write-command-descriptions
  "Write command descriptions to HOP_HOP_DIR metadata."
  [descriptions]
  (def keys @[])
  (eachp pair descriptions
    (def command (get pair 0))
    (def description (get pair 1))
    (when (and description (not= "" description))
      (array/push keys command)))
  (sort keys)
  (def out @"")
  (each command keys
    (buffer/push-string out (meta-escape command) "\t" (meta-escape (get descriptions command)) "\n"))
  (def f (file/open (metadata-path) :w))
  (file/write f out)
  (file/close f))

## ----------------------------------------------------------------------------

(defn strip-command-suffix
  "Remove a supported script suffix from a file name."
  [file]
  (var command file)
  (each suffix command-suffixes
    (when (string/has-suffix? suffix file)
      (set command (string/slice file 0 (- (length file) (length suffix))))))
  command)

(defn command-file?
  "Check if a file can be exposed as a Hop Hop command."
  [full-path file]
  (or
    (not (nil? (os/stat (string full-path ".sh"))))
    (not (nil? (os/stat (string full-path ".py"))))
    (not (nil? (os/stat (string full-path ".janet"))))
    (not (nil? (os/stat (string full-path ".exs"))))
    (= :file (get (os/stat full-path) :mode))))

(defn collect-commands-rec
  "Collect available commands recursively as dot-separated names."
  [dir prefix commands]
  (each file (os/dir dir)
    (let [full-path (path/join dir file)]
      (if (is-directory? full-path)
        (collect-commands-rec full-path (string prefix (strip-command-suffix file) ".") commands)
        (when (and (not (metadata-file? file)) (command-file? full-path file))
          (array/push commands (string prefix (strip-command-suffix file)))))))
  commands)

(defn collect-commands
  "Collect available commands in HOP_HOP_DIR."
  []
  (def hophoppath (os/getenv "HOP_HOP_DIR"))
  (sort (collect-commands-rec hophoppath "" @[])))

(defn command-exists?
  "Check if a command exists in HOP_HOP_DIR."
  [name]
  (var found false)
  (each command (collect-commands)
    (when (= command name)
      (set found true)))
  found)

(defn max-command-length
  "Return the length of the longest command name."
  [commands]
  (var max-len 0)
  (each command commands
    (when (> (length command) max-len)
      (set max-len (length command))))
  max-len)

(defn print-command-list
  "Print command names with optional descriptions."
  [commands descriptions]
  (def width (max-command-length commands))
  (each command commands
    (def description (get descriptions command))
    (if (and description (not= "" description))
      (printf "%s%s  %s" command (string/repeat " " (- width (length command))) description)
      (print command))))

(defn list-commands
  "List all available commands in HOP_HOP_DIR"
  [args]
  (if (= "--plain" (get args 0))
    (each command (collect-commands)
      (print command))
    (do
      (print "Available commands:")
      (print-command-list (collect-commands) (read-command-descriptions)))))

(defn describe-command
  "Set a command description in HOP_HOP_DIR metadata."
  [args]
  (def command (get args 0))
  (def description-parts (array/slice args 1))
  (cond
    (nil? command)
      (do
        (print "USAGE: hophop describe <command> <description>")
        (os/exit 1))
    (empty? description-parts)
      (do
        (print "USAGE: hophop describe <command> <description>")
        (os/exit 1))
    (not (command-exists? command))
      (do
        (printf "Unknown command: %s" command)
        (os/exit 1))
    (do
      (def descriptions (read-command-descriptions))
      (put descriptions command (string/join description-parts " "))
      (write-command-descriptions descriptions)
      (printf "Updated description for %s." command))))

(defn print-zsh-completion
  "Print a zsh completion script for hophop."
  []
  (print "#compdef hophop hh")
  (print "")
  (print "_hophop() {")
  (print "  local -a commands")
  (print "  commands=(${(f)\"$(hophop list --plain 2>/dev/null)\"})")
  (print "  _describe 'hophop command' commands")
  (print "}")
  (print "")
  (print "compdef _hophop hophop")
  (print "compdef _hophop hh"))

(defn print-completion
  "Print shell completion script."
  [args]
  (case (get args 0)
    "zsh" (print-zsh-completion)
    (do
      (printf "Unsupported shell: %s\n" (get args 0))
      (print "USAGE: hophop completion zsh")
      (os/exit 1))))

## MAIN
## ----------------------------------------------------------------------------

(defn hophop-main
  "Main function to run the hophop command"
  []
  (let [args (dyn :args)]
    (def [_ command & rest] args)
    (case command
      "help" (printf "Hop Hop <Something>!\nUSAGE: hophop help | hophop list | hophop describe <command> <description> | hophop <command> [args]")
      "list" (list-commands rest)
      "describe" (describe-command rest)
      "completion" (print-completion rest)
      (run-command command rest))))

(defn main
  [& args]
  (def hophoppath (os/getenv "HOP_HOP_DIR"))
  (if (nil? hophoppath)
    (do (printf "HOP_HOP_DIR is not set")
      (os/exit 1)))
  (let [args (dyn :args)]
    (if (= "-h" (get args 1))
      (do
        (print "Usage: hophop [-h] COMMAND..")
        (os/exit 0))))

  (hophop-main))

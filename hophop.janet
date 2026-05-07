(import path)

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
        (when (command-file? full-path file)
          (array/push commands (string prefix (strip-command-suffix file)))))))
  commands)

(defn collect-commands
  "Collect available commands in HOP_HOP_DIR."
  []
  (def hophoppath (os/getenv "HOP_HOP_DIR"))
  (collect-commands-rec hophoppath "" @[]))

(defn list-commands-rec
  "List all available commands recursively with indentation."
  [path indent]
  (each cmd (os/dir path)
    (let [full-path (path/join path cmd)
          indent-str (string/repeat "  " indent)]
      (printf "%s- %s" indent-str cmd)
      (when (is-directory? full-path)
        (list-commands-rec full-path (inc indent))))))

(defn list-commands
  "List all available commands in HOP_HOP_DIR"
  [args]
  (if (= "--plain" (get args 0))
    (each command (collect-commands)
      (print command))
    (do
      (print "Available commands:")
      (def hophoppath (os/getenv "HOP_HOP_DIR"))
      (list-commands-rec hophoppath 0))))

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

(defn hophop-main
  "Main function to run the hophop command"
  []
  (let [args (dyn :args)]
    (def [_ command & rest] args)
    (case command
      "help" (printf "Hop Hop <Something>!\nUSAGE: hophop help | hophop list | hophop <command> [args]")
      "list" (list-commands rest)
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

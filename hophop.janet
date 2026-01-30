(import path)
(use sh)

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
      (string/has-suffix? ".py" command-path) ($ "python3" ,command-path ;args)
      (string/has-suffix? ".janet" command-path) ($ "janet" ,command-path ;args)
      (string/has-suffix? ".exs" command-path) ($ "elixir" ,command-path ;args)
      (os/execute @[command-path] :p))))

(defn is-directory? [path]
  (= :directory (get (os/stat path) :mode)))

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
  []
  (print "Available commands:")
  (def hophoppath (os/getenv "HOP_HOP_DIR"))
  (list-commands-rec hophoppath 0))

(defn hophop-main
  "Main function to run the hophop command"
  []
  (let [args (dyn :args)]
    (def [_ command & rest] args)
    (case command
      "help" (printf "Hop Hop <Something>!\nUSAGE: hophop help | hophop list | hophop <command> [args]")
      "list" (list-commands)
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

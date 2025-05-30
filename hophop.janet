(import path)
(use sh)

(defn get-command-type
  "Check if the given base script name is one of the supported types."
  [base]
  (cond
    (not (nil? (os/stat (string base ".sh")))) :sh
    (not (nil? (os/stat (string base ".py")))) :py
    (not (nil? (os/stat (string base ".janet")))) :janet
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
      :exe base)))

(defn run-command
  "Run the command. If command is `foo.bar` it will look into `/foo/bar` in
  HOP_HOP_DIR and run it."
  [command args]
  (let [command-path (command-to-path command)]
    (cond
      (string/has-suffix? ".sh" command-path) (os/execute [command-path ;args])
      (string/has-suffix? ".py" command-path) ($ "python3" ,command-path ;args)
      (string/has-suffix? ".janet" command-path) ($ "janet" ,command-path ;args)
      (os/execute [(command-path)]))))

(defn hophop-main
  "Main function to run the hophop command"
  []
  (let [args (dyn :args)]
    (def [_ command & rest] args)
    # (printf "Running %j" (command-to-path command))
    (run-command command rest)))

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

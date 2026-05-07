(declare-project
  :name "hophop"
  :description "Instant script runner."

  # Optional urls to git repositories that contain required artifacts.
  :dependencies ["https://github.com/janet-lang/path.git"])

(declare-executable
 :name "hophop"
 :entry "hophop.janet"
 :install true)

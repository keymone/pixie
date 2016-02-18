(ns pixie.regex
  (:require [pixie.ffi-infer :as i]))

(i/with-config {:library "cre2"
                :cxx-flags ["-Lexternals/cre2/build/.libs"
                            "-lcre2"
                            "-Iexternals/cre2/src"]
                :includes ["cre2.h"]}

  (i/defcstruct cre2_string_t [:data :length])
  (i/defcfn cre2_version_string)

  ;; Options
  (i/defcfn cre2_opt_new)
  (i/defcfn cre2_opt_delete)
  (i/defcfn cre2_opt_set_posix_syntax)
  (i/defcfn cre2_opt_set_longest_match)
  (i/defcfn cre2_opt_set_log_errors)
  (i/defcfn cre2_opt_set_literal)
  (i/defcfn cre2_opt_set_never_nl)
  (i/defcfn cre2_opt_set_case_sensitive)
  (i/defcfn cre2_opt_set_perl_classes)
  (i/defcfn cre2_opt_set_word_boundary)
  (i/defcfn cre2_opt_set_one_line)
  (i/defcfn cre2_opt_set_max_mem)
  (i/defcfn cre2_opt_set_encoding)

  ;; Construction / destruction
  (i/defcfn cre2_new)
  (i/defcfn cre2_delete)

  ;; Inspection
  (i/defcfn cre2_pattern)
  (i/defcfn cre2_error_code)
  (i/defcfn cre2_num_capturing_groups)
  (i/defcfn cre2_program_size)

  ;; Errors something?
  (i/defcfn cre2_error_string)
  (i/defcfn cre2_error_arg)

  ;; Matching
  (i/defcstruct cre2_range_t [:start :past])
  (i/defcfn cre2_match)
  (i/defcfn cre2_easy_match)
  (i/defcfn cre2_strings_to_ranges)
)

(def optmap
  { :ascii #(cre2_set_encoding % 2)
    :posix #(cre2_opt_set_posix_syntax % 1)
    :longest_match #(cre2_opt_set_longest_match % 1)
    :silent #(cre2_opt_set_log_errors % 0)
    :literal #(cre2_opt_set_literal % 1)
    :never_nl #(cre2_opt_set_never_nl % 1)
    :dot_nl #(cre2_opt_set_one_line % 0)
    :never_capture #(do %) ;; ??
    :ignore_case #(cre2_opt_set_case_sensitive % 0) })

(defn- cre2-opts [opts]
  (let [opt (cre2_opt_new)]
    (doseq [key opts] ((key optmap) opt))
    opt))

(defn regexp
  {:doc "Returns internal representation for regular
   expression, used in matching functions."
   :signatures [[rexegp-str opts]]}
  [regexp-str opts]
  (cre2_new regexp-str (count regexp-str) (cre2-opts opts)))

(defn match
  [pattern text]
  (cre2_match
   pattern
   text
   (count text)
   0
   (count text)
   1 ;; anchor 1 - no, 2 - start, 3 - both
   (cre2_string_t)
   (+ 1 (cre2_num_capturing_groups pattern))))

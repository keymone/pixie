(ns pixie.re
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

(def cre2_optmap
  { :ascii #(cre2_set_encoding % 2)
    :posix #(cre2_opt_set_posix_syntax % 1)
    :longest_match #(cre2_opt_set_longest_match % 1)
    :silent #(cre2_opt_set_log_errors % 0)
    :literal #(cre2_opt_set_literal % 1)
    :never_nl #(cre2_opt_set_never_nl % 1)
    :dot_nl #(cre2_opt_set_one_line % 0)
    :never_capture #(do %) ;; ??
    :ignore_case #(cre2_opt_set_case_sensitive % 0) })

(defn cre2_make_opts [opts]
  (let [opt (cre2_opt_new)]
    (doseq [key opts] ((key cre2_optmap) opt))
    opt))

(defn cre2_run_match
  [pattern text]
  (= 1
     (cre2_match pattern
        text (count text)
        0 (count text)
        1 ;; anchor 1 - no, 2 - start, 3 - both
        (cre2_string_t)
        (+ 1 (cre2_num_capturing_groups pattern)))))

(defprotocol IRegex
  (re-matches [r t]))

(deftype CRE2Regex [pattern opts]
  IFinalize
  (-finalize! [this]
    (cre2_opt_delete opts)
    (cre2_delete pattern))

  IRegex
  (re-matches [_ text] (cre2_run_match pattern text)))

(def ^:dynamic *default-re-engine* :cre2)

;; an "open" engine registry
(defmulti re-engine (fn [k s o] k))

;; add cre2 to registry
(defmethod re-engine :cre2 [_ regex-str opts]
  (let [copts (cre2_make_opts opts)]
    (->CRE2Regex (cre2_new regex-str (count regex-str) copts) copts)))

(defn regex
  {:doc "Returns internal representation for regular
   expression, used in matching functions."
   :signatures [[rexeg-str opts]]}
  ([pattern opts] (regex pattern opts *default-re-engine*))
  ([pattern opts engine] (re-engine engine pattern opts)))

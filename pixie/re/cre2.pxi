(ns pixie.re.cre2
  (:require [pixie.ffi-infer :as f]
            [pixie.re :as re]))

(f/with-config {:library "cre2"
                :includes ["cre2.h"]}

  (f/defcstruct cre2_string_t [:data :length])
  (f/defcfn cre2_version_string)

  ;; Options
  (f/defcfn cre2_opt_new)
  (f/defcfn cre2_opt_delete)
  (f/defcfn cre2_opt_set_posix_syntax)
  (f/defcfn cre2_opt_set_longest_match)
  (f/defcfn cre2_opt_set_log_errors)
  (f/defcfn cre2_opt_set_literal)
  (f/defcfn cre2_opt_set_never_nl)
  (f/defcfn cre2_opt_set_case_sensitive)
  (f/defcfn cre2_opt_set_perl_classes)
  (f/defcfn cre2_opt_set_word_boundary)
  (f/defcfn cre2_opt_set_one_line)
  (f/defcfn cre2_opt_set_max_mem)
  (f/defcfn cre2_opt_set_encoding)

  ;; Construction / destruction
  (f/defcfn cre2_new)
  (f/defcfn cre2_delete)

  ;; Inspection
  (f/defcfn cre2_pattern)
  (f/defcfn cre2_error_code)
  (f/defcfn cre2_num_capturing_groups)
  (f/defcfn cre2_program_size)

  ;; Errors something?
  (f/defcfn cre2_error_string)
  (f/defcfn cre2_error_arg)

  ;; Matching
  (f/defcstruct cre2_range_t [:start :past])
  (f/defcfn cre2_match)
  (f/defcfn cre2_easy_match)
  (f/defcfn cre2_strings_to_ranges)
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

(deftype CRE2Regex [pattern opts]
  IFinalize
  (-finalize! [this]
    (cre2_opt_delete opts)
    (cre2_delete pattern))

  re/IRegex
  (re/re-matches [_ text] (cre2_run_match pattern text)))

;; add cre2 to registry
(defmethod re/re-engine :cre2 [_ regex-str opts]
  (let [copts (cre2_make_opts opts)]
    (->CRE2Regex (cre2_new regex-str (count regex-str) copts) copts)))
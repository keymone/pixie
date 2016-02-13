(ns pixie.regex
  (:require [pixie.ffi-infer :as i]))

(i/with-config {:library "cre2"
                :cxx-flags [" && pwd"
                            "-Lexternals/cre2/build/.libs"
                            "-lcre2"
                            "-Iexternals/cre2/src"]
                :includes ["cre2.h"]}
  (i/defconst M_E)

  (i/defcfn rint))
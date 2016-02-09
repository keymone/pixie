(ns pixie.regex
  (:require [pixie.ffi-infer :as i]))

(i/with-config {:library "re2"
                :cxx-flags ["-lre2"]
                :includes ["re2.h"]}
  (i/defconst M_E)
  (i/defconst M_LOG2E)
  (i/defconst M_LOG10E)
  (i/defconst M_LN2)
  (i/defconst M_LN10)
  (i/defconst M_PI)
  (i/defconst M_PI_2)
  (i/defconst M_PI_4)
  (i/defconst M_1_PI)
  (i/defconst M_2_PI)
  (i/defconst M_2_SQRTPI)
  (i/defconst M_SQRT2)
  (i/defconst M_SQRT1_2)

  (i/defcfn nan)
  (i/defcfn ceil)
  (i/defcfn floor)
  (i/defcfn nearbyint)
  (i/defcfn rint)
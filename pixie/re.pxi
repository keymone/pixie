(ns pixie.re)

(defprotocol IRegex
  (re-matches [r t]))

(def ^:dynamic *default-re-engine* :cre2)

;; an "open" engine registry
(defmulti re-engine (fn [k s o] k))

(defn regex
  {:doc "Returns internal representation for regular
   expression, used in matching functions."
   :signatures [[rexeg-str opts]]}
  ([pattern opts] (regex pattern opts *default-re-engine*))
  ([pattern opts engine] (re-engine engine pattern opts)))

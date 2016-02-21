(in-ns :pixie.stdlib)

(defprotocol IRegex
  (re-matches [r t])
  (re-find [r t])
  (re-seq [r t]))

(def ^:dynamic *default-re-engine* 'pixie.re.cre2)

;; an "open" engine registry
(defmulti re-engine (fn [k s o] k))

(defn re-pattern
  {:doc "Returns internal representation for regular
   expression, used in matching functions."
   :signatures [[rexeg-str opts]]}
  ([pattern opts] (re-pattern pattern opts *default-re-engine*))
  ([pattern opts engine] (re-engine engine pattern opts)))

(load-ns *default-re-engine*)

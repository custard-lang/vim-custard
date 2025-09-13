(module conjure.client.custard.stdio
  {autoload {a conjure.aniseed.core
             str conjure.aniseed.string
             nvim conjure.aniseed.nvim
             stdio conjure.remote.stdio
             config conjure.config
             text conjure.text
             mapping conjure.mapping
             client conjure.client
             log conjure.log
             ts conjure.tree-sitter}
   require-macros [conjure.macros]})

(define :conjure.client.custard.stdio)

(config.merge
  {:client
   {:custard
    {:stdio
     {:mapping {:start "cs"
                :stop "cS"
                :interrupt "ei"}
      :command "npx custard repl"
      :prompt_pattern "\n?[-_%w.[]/()]+:%d+:[.>][.>][.>] "}}}})

(when (config.get-in [:mapping :enable_defaults])
  (config.merge
    {:client
     {:racket
      {:stdio
       {:mapping {:start "cs"
                  :stop "cS"
                  :interrupt "ei"}}}}}))

(def- cfg (config.get-in-fn [:client :custard :stdio]))

(defonce- state (client.new-state (fn [] {:repl nil})))

(def buf-suffix ".cstd")

(def comment-prefix "")

(defn- with-repl-or-warn [f opts]
  (let [repl (state :repl)]
    (if repl
      (f repl)
      (log.append [(.. comment-prefix "No REPL running")]))))

(defn- format-message [msg]
  (str.split (or msg.out msg.err) "\n"))

(defn- display-result [msg]
  (log.append
    (->> (format-message msg)
         (a.filter #(not (= "" $1))))))

(defn eval-str [opts]
  (with-repl-or-warn
    (fn [repl]
      (repl.send
        (prep-code opts.code)
        (fn [msgs]
          (when (and (= 1 (a.count msgs))
                     (= "" (a.get-in msgs [1 :out])))
            (a.assoc-in msgs [1 :out] (.. comment-prefix "Empty result.")))

          (opts.on-result (str.join "\n" (a.mapcat format-message msgs)))
          (a.run! display-result msgs))
        {:batch? true}))))

(defn doc-str [opts]
  (eval-str (a.update opts :code #(.. ",doc " $1))))

(defn- display-repl-status [status]
  (let [repl (state :repl)]
    (when repl
      (log.append
        [(.. comment-prefix (a.pr-str (a.get-in repl [:opts :cmd])) " (" status ")")]
        {:break? true}))))

(defn stop []
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (a.assoc (state) :repl nil))))

(defn enter []
  (let [repl (state :repl)
        path (nvim.fn.expand "%:p")]
    (when (and repl (not (log.log-buf? path)))
      (repl.send
        (prep-code (.. ":load " path))
        (fn [])))))

(defn start []
  (if (state :repl)
    (log.append ["; Can't start, REPL is already running."
                 (.. "; Stop the REPL with "
                     (config.get-in [:mapping :prefix])
                     (cfg [:mapping :stop]))]
                {:break? true})
    (a.assoc
      (state) :repl
      (stdio.start
        {:prompt-pattern (cfg [:prompt_pattern])
         :cmd (cfg [:command])

         :on-success
         (fn []
           (display-repl-status :started)
           (enter))

         :on-error
         (fn [err]
           (display-repl-status err))

         :on-exit
         (fn [code signal]
           (when (and (= :number (type code)) (> code 0))
             (log.append [(.. comment-prefix "process exited with code " code)]))
           (when (and (= :number (type signal)) (> signal 0))
             (log.append [(.. comment-prefix "process exited with signal " signal)]))
           (stop))

         :on-stray-output
         (fn [msg]
           (display-result msg))}))))

(defn on-load []
  (start))

(defn on-filetype []
  (augroup
    conjure-racket-stdio-bufenter
    (autocmd :BufEnter (.. :* buf-suffix) (viml->fn :enter)))

  (mapping.buf
    :CustardStart (cfg [:mapping :start])
    start
    {:desc "Start the REPL"})

  (mapping.buf
    :CustardStop (cfg [:mapping :stop])
    stop
    {:desc "Stop the REPL"})

  (mapping.buf
    :CustardInterrupt (cfg [:mapping :interrupt])
    interrupt
    {:desc "Interrupt the current evaluation"}))

(defn on-exit []
  (stop))

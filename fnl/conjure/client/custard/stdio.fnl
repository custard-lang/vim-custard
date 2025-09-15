(local {: autoload : define} (require :conjure.nfnl.module))
(local a (autoload :conjure.aniseed.core))
(local client (autoload :conjure.client))
(local config (autoload :conjure.config))
(local log (autoload :conjure.log))
(local mapping (autoload :conjure.mapping))
(local nvim (autoload :conjure.aniseed.nvim))
(local stdio (autoload :conjure.remote.stdio))
(local str (autoload :conjure.nfnl.string))
(local text (autoload :conjure.text))
(local ts (autoload :conjure.tree-sitter))

(local M (define :conjure.client.custard.stdio))

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

(local cfg (config.get-in-fn [:client :custard :stdio]))

(local state (client.new-state (fn [] {:repl nil})))

(set M.buf-suffix ".cstd")

(set M.comment-prefix "")

(fn with-repl-or-warn [f opts]
  (let [repl (state :repl)]
    (if repl
      (f repl)
      (log.append [(.. comment-prefix "No REPL running")]))))

(fn format-message [msg]
  (str.split (or msg.out msg.err) "\n"))

(fn display-result [msg]
  (log.append
    (->> (format-message msg)
         (a.filter #(not (= "" $1))))))

(fn M.eval-str [opts]
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

(fn M.doc-str [opts]
  (eval-str (a.update opts :code #(.. ",doc " $1))))

(fn display-repl-status [status]
  (let [repl (state :repl)]
    (when repl
      (log.append
        [(.. comment-prefix (a.pr-str (a.get-in repl [:opts :cmd])) " (" status ")")]
        {:break? true}))))

(fn M.stop []
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (a.assoc (state) :repl nil))))

(fn M.enter []
  (let [repl (state :repl)
        path (nvim.fn.expand "%:p")]
    (when (and repl (not (log.log-buf? path)))
      (repl.send
        (prep-code (.. ":load " path))
        (fn [])))))

(fn M.start []
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

(fn M.on-load []
  (start))

(fn M.on-filetype []
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

(fn M.on-exit []
  (stop))

M

(module conjure.client.custard.stdio
  {autoload {stdio conjure.remote.stdio
             config conjure.config}
   require-macros [conjure.macros]})

(config.merge
  {:client
   {:custard
    {:stdio
     {:mapping {:start "cs"
                :stop "cS"
                :interrupt "ei"}
      :command "custard"
      :prompt_pattern "\ncustard> "}}}})

; TODO: Current Custard's REPL is useless because it evaluates only by line. Give up.

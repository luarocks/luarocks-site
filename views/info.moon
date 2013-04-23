
import time_ago_in_words from require "lapis.util"

class Info extends require "widgets.base"
  content: =>
    h2 "Workers"
    element "table", class: "table", ->
      thead ->
        tr ->
          td "PID"
          td "Memory"
          td "Last Access"
      for worker in *@workers
        tr ->
          td class: "pid", worker.pid
          td class: "mem", @format_bytes math.floor(worker.mem * 1000)
          td class: "time_ago", time_ago_in_words worker.time

    h2 "Build"
    pre ->
      text require "revision"


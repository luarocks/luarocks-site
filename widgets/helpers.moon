
date = require "date"
import time_ago_in_words from require "lapis.util"

class Helpers
  raw_ssi: (fname) =>
    res = ngx.location.capture "/static/md/#{fname}"
    error "Failed to include SSI `#{fname}`" unless res.status == 200
    raw res.body

  plural: (num, single, plural) =>
    if num == 1
      "#{num} #{single}"
    else
      "#{@format_number num} #{plural}"

  format_number: (num) =>
    tostring(num)\reverse!\gsub("(...)", "%1,")\match("^(.-),?$")\reverse!

  format_big_number: (num) =>
    if num >= 10000000
      "#{math.floor(num / 1000000)}m"
    else if num >= 1000000
      "#{math.floor(num / 100000) / 10}m"
    else if num >= 100000
      "#{math.floor(num / 1000)}k"
    else if num >= 10000
      "#{math.floor(num / 100) / 10}k"
    else
      @format_number num

  format_url: (str) =>
    return str if str\match "^(%w+)://"
    "http://" .. str

  truncate: (str, length) =>
    return str if #str <= length
    str\sub(1, length) .. "..."

  format_duration: do
    limits = {
      {"y", 60*60*24*365}
      {"w", 60*60*24*7}
      {"d", 60*60*24}
      {"h", 60*60}
      {"m", 60}
      {"s", 1}
      {"ms", 1/1000}
    }

    (seconds) =>
      for {label, min} in *limits
        if seconds > min or min < 1
          formatted = "%0.2f"\format(seconds / min)\gsub "%.0+$", ""
          return "#{formatted} #{label}"

      "#{seconds} s"

  format_bytes: do
    limits = {
      {"gb", 1024^3}
      {"mb", 1024^2}
      {"kb", 1024}
    }

    (bytes) =>
      bytes = math.floor bytes
      suffix = " bytes"
      for {label, min} in *limits
        if bytes >= min
          bytes = math.floor bytes / min
          suffix = label
          break

      @format_number(bytes) .. suffix

  filesize_format: (bytes) => @format_bytes bytes

  copy_button: (value, label="Copy to clipboard") =>
    button {
      type: "button"
      class: "copy_button"
      "data-copy": value
      "aria-label": label
      title: label
    }, ->
      raw [[<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>]]

  render_hash_cell: (hash, opts={}) =>
    unless hash
      span class: "nil_value", "—"
      return

    span class: "hash_cell", ->
      display = if opts.truncate
        hash\sub(1, opts.truncate) .. "…"
      else
        hash
      span class: "hash", title: hash, display
      @copy_button hash, "Copy hash to clipboard"

  render_date: (d, abs_first=false) =>
    span class: "date", title: date(d)\fmt("${iso}Z"), @format_relative_timestamp(d)

  format_relative_timestamp: (d, extra_opts) =>
    now = date true

    suffix = if date(true) < date(d)
      "from now"
    else
      "ago"

    time_ago_in_words d, nil, suffix

  format_short_age: (d) =>
    now = date true
    diff = date.diff now, date(d)
    seconds = diff\spanseconds!

    if seconds < 60
      "#{math.floor seconds}s"
    elseif seconds < 60 * 60
      "#{math.floor seconds / 60}m"
    elseif seconds < 60 * 60 * 24
      "#{math.floor seconds / (60 * 60)}h"
    elseif seconds < 60 * 60 * 24 * 30
      "#{math.floor seconds / (60 * 60 * 24)}d"
    elseif seconds < 60 * 60 * 24 * 365
      "#{math.floor seconds / (60 * 60 * 24 * 30)}mo"
    else
      "#{math.floor seconds / (60 * 60 * 24 * 365)}y"


date = require "date"

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

  render_date: (d, abs_first=false) =>
    import time_ago_in_words from require "lapis.util"
    span class: "date", title: date(d)\fmt "${iso}Z", @format_relative_timestamp(d)

  format_relative_timestamp: (d, extra_opts) =>
    now = date true

    suffix = if date(true) < date(d)
      "from now"
    else
      "ago"

    time_ago_in_words tostring(d), nil, suffix

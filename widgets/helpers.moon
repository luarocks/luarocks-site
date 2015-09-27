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
    span class: "date", title: tostring(d), time_ago_in_words(d)


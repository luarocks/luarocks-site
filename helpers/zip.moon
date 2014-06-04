

ZipWriter = require "ZipWriter"

zipped_file = (fname, content) ->
  zip = ZipWriter.new!
  buffer = {}

  zip\open_writer (data) ->
    return unless data
    table.insert buffer, data

  zip\write fname, {
    isfile: true
    istext: true
    isdir: false
    exattrib: 0x81b60020 -- from https://github.com/moteus/ZipWriter/issues/2
  }, coroutine.wrap ->
    coroutine.yield content

  zip\close!
  table.concat buffer

{ :zipped_file }

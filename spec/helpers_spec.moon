

describe "helpers.manifests", ->
  import build_manifest, serve_lua_table from require "helpers.manifests"

  local req_stub

  before_each ->
    req_stub = { res: { headers: {} } }

  it "serializes empty table", ->
    assert.same {
      { layout: false }
      ''
    }, {
      serve_lua_table req_stub, {}
    }


  it "serializes simple table", ->
    assert.same {
      { layout: false }
      [[
hello = {
   world = {
      "a", "b", "c"
   }
}
]]
    }, {
      serve_lua_table req_stub, {
        hello: {
          world: {"a", "b", "c"}
        }
      }
    }

  it "fails to serialize with invalid top level key", ->
    assert.has_error(
      ->
        serve_lua_table req_stub, {
          "function": { 1 }
        }
      "Invalid top level key: function"
    )

  it "serializes table with lua keywords", ->
    assert.same {
      { layout: false }
      [[
thing = {
   ["end"] = 55,
   ["function"] = {
      ["do"] = true
   }
}
]]
    }, {
      serve_lua_table req_stub, {
        thing: {
          "function": {
            "do": true
          }
          "end": 55
        }
      }
    }

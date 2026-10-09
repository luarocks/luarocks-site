describe "helpers.manifests", ->
  import build_manifest, serve_lua_table from require "helpers.manifests"

  local req_stub
  local req_stub2

  before_each ->
    req_stub = { res: { headers: {}}, version: "5.2"  }

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

  before_each ->
    req_stub2 = { res: { headers: {}}, version: "5.1"  }

  it "serializes empty table 5.1", ->
    assert.same {
      { layout: false }
      ''
    }, {
      serve_lua_table req_stub2, {}
    }


  it "serializes simple table 5.1", ->
    assert.same {
      { layout: false }
      [[
hello = {
   world = (function () return {
      "a", "b", "c"
   } end)()
}
]]
    }, {
      serve_lua_table req_stub2, {
        hello: {
          world: {"a", "b", "c"}
        }
      }
    }

  it "fails to serialize with invalid top level key 5.1", ->
    assert.has_error(
      ->
        serve_lua_table req_stub2, {
          "function": { 1 }
        }
      "Invalid top level key: function"
    )

  it "serializes table with lua keywords 5.1", ->
    assert.same {
      { layout: false }
      [[
thing = {
   ['end'] = 55,
   ['function'] = (function () return {
      ['do'] = true
   } end)()
}
]]
    }, {
      serve_lua_table req_stub2, {
        thing: {
          "function": {
            "do": true
          }
          "end": 55
        }
      }
    }
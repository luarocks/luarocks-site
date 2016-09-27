import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import Modules, Users, ApprovedLabels from require "models"
import ToolboxImport from require "helpers.toolbox"

modules = {
}

labels = {
  {
    id: 1
    name: "my cool label"
  }
  {
    id: 2
    name: "my uncool label"
  }
}


describe "helpers.toolbox", ->
  use_test_env!

  setup ->
    truncate_tables Modules, Users, ApprovedLabels

  it "imports labels", ->
    toolbox = ToolboxImport modules, labels
    toolbox\create_approved_labels!

    count = ApprovedLabels\count!
    assert.equal count, #labels
    assert.same {
      "my-cool-label"
      "my-uncool-label"
    }, [l.name for l in *ApprovedLabels\select "order by name"]

  it "applies labels", ->
    assert.has.no.errors toolbox\apply_labels_to_modules
    


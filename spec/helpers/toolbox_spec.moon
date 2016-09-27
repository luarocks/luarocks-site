import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import Modules, Users, ApprovedLabels from require "models"
import ToolboxImport from require "helpers.toolbox"

modules = {
  {
    id: 777
    name: "swell-module"
    labels: { 2 }
  }
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

  local toolbox

  before_each ->
    truncate_tables Modules, Users, ApprovedLabels
    toolbox = ToolboxImport modules, labels

  it "imports labels", ->
    toolbox\create_approved_labels!

    count = ApprovedLabels\count!
    assert.equal count, #labels
    assert.same {
      "my-cool-label"
      "my-uncool-label"
    }, [l.name for l in *ApprovedLabels\select "order by name"]

  it "applies labels", ->
    mod = factory.Modules name: "swell-module"
    toolbox = ToolboxImport modules, labels
    assert.has.no.errors toolbox\apply_labels_to_modules

    mod\refresh!
    assert.same {"my-uncool-label"}, mod.labels


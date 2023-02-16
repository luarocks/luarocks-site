factory = require "spec.factory"

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
  local toolbox

  import Modules, Users, ApprovedLabels, Manifests, ManifestModules from require "spec.models"

  before_each ->
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

  it "gets modules to follow #ddd", ->
    user = factory.Users {
      email: "test@itch.zone"
    }

    root = Manifests\root!

    -- only one choice
    m1 = factory.Modules {
      name: "mod1"
    }

    -- two options, root and not root
    m2_1 = factory.Modules {
      name: "mod2"
    }

    m2_2 = factory.Modules {
      name: "mod2"
    }

    ManifestModules\create root, m2_2

    -- two options, sort by downloads
    m3_1 = factory.Modules {
      name: "mod3"
      downloads: 10
    }

    m3_2 = factory.Modules {
      name: "mod3"
      downloads: 200
    }

    toolbox = ToolboxImport {
      {
        id: 1
        name: "mod1"
      }
      {
        id: 2
        name: "mod2"
      }
      {
        id: 3
        name: "mod3"
      }
      {
        id: 4
        name: "mod4"
      }
    }, {}, {
      {
        email: "test@itch.zone"
        endorsements: {
          "1"
          "2"
          "3"
          "4"
        }
      }
    }

    modules = toolbox\modules_endorsed_by_user user
    assert.same {
      [m1.id]: true
      [m2_2.id]: true
      [m3_2.id]: true
    }, {m.id, true for m in *modules}

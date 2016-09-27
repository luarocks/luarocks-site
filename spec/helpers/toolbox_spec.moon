import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import Modules, Labels from require "models"

toolbox = require "helpers.toolbox"

import use_test_server from require "lapis.spec"

import
  modules
  labels
  from require "secrets.toolbox"


describe "helpers.toolbox", ->
  use_test_server!

  setup ->
    truncate_tables Labels

  it "imports labels", ->
    toolbox\create_labels_from_dump!
    count = Labels\count!
    assert.equal count, #labels

  it "applies labels", ->
    assert.has.no.errors toolbox\apply_labels_to_modules
    


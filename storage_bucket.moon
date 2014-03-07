
-- 
config = require("lapis.config").get!

local bucket

unless config._name == "test"
  pcall ->
    bucket = require "secret.storage_bucket"

unless bucket
  import MockStorage from require "cloud_storage.mock"
  s = MockStorage("static/storage", "http://127.0.0.1:8080")
  bucket = s\bucket "default_bucket"

bucket

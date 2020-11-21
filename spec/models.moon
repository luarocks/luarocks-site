-- this will let you import specs and also set up truncation
-- you should call this inside a descibe block

-- import Users, Rocks from require "spec.models"

setmetatable {}, {
  __index: (model_name) =>
    import truncate_tables from require "lapis.spec.db"
    import before_each from require "busted"

    with m = assert require("models")[model_name], "invalid model: #{model_name}"
      before_each ->
        truncate_tables m
}

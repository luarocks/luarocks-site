
get_keys = ->
  return nil, "not in nginx" unless ngx and ngx.shared
  dict = ngx.shared.pagecache_versions
  return nil, "no dictionary" unless dict

  keys = dict\get_keys!

  return for key in *keys
    {key, dict\get key}

version_for_path = (path) ->
  return nil, "not in nginx" unless ngx and ngx.shared
  dict = ngx.shared.pagecache_versions
  return nil, "no dictionary" unless dict

  key = "pc:#{path}"

  time = dict\get key

  unless time
    t = ngx.time!
    time = if dict\add key, t
      t
    else
      dict\get key

  time

purge_pattern = (pattern) ->
  return nil, "not in nginx" unless ngx and ngx.shared
  dict = ngx.shared.pagecache_versions
  return nil, "no dict" unless dict

  purged = 0
  for key in *dict\get_keys!
    if key\match pattern
      if dict\delete key
        purged += 1

  purged

purge_keys = (keys) ->
  return nil, "not in nginx" unless ngx and ngx.shared
  dict = ngx.shared.pagecache_versions
  return nil, "no dict" unless dict

  for key in *keys
    dict\delete key

  true


{:purge_keys, :version_for_path, :get_keys, :purge_pattern}


version_for_path = (path) ->
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

purge_keys = (keys) ->
  return nil, "not in nginx" unless ngx and ngx.shared
  dict = ngx.shared.pagecache_versions
  return nil, "no dict" unless dict

  for key in *keys
    dict\delete key

  true


{:purge_keys, :version_for_path}

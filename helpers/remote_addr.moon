->
  return unless ngx
  -- NOTE: be careful about trusting x-forwarded-for
  original = ngx.var.http_x_forwarded_for
  original = nil if original == ""
  original or ngx.var.remote_addr


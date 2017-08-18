
class UserDigest extends require "emails.base"
  subject: => "LuaRocks Digest"
  content: =>
    h2 "Hello #{@user\name_for_display!}, here is your weekly digest from LuaRocks, enjoy!"


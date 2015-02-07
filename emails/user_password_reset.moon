
class UserPasswordResetEmail extends require "emails.base"
  subject: => "Reset your password"
  content: =>
    h2 "Reset your password"
    p "Hello #{@user.username},"
    p "Someone attempted to reset your password on LuaRocks. If that person
    was you, click the link below to update your password. If it wasn't you
    then you don't have to do anything."

    p ->
      a href: @reset_url, @reset_url



class UserSettingsTfaScratchcodes extends require "widgets.user_settings_page"
  settings_content: =>
    if @new_scratchcodes and #@new_scratchcodes > 0
      heading = if @new_scratchcodes_reason == "regenerated"
        "Backup codes regenerated"
      else
        "Two-factor authentication is now enabled"

      h3 heading

      p ->
        b "Save these backup codes now. "
        text "They will not be shown again. Each code can be used once in
        place of a verification code if you lose access to your authenticator."

      ul class: "scratchcodes", ->
        for c in *@new_scratchcodes
          li ->
            code c

      if @new_scratchcodes_reason == "regenerated"
        p "Any previously-issued backup codes are no longer valid."

      p ->
        a href: @url_for("user_settings.two_factor_auth"), "Return to two-factor authentication settings"
    else
      p "There are no new backup codes to display. Backup codes are stored
      securely and only shown once when generated."
      p ->
        a href: @url_for("user_settings.two_factor_auth"), "Return to two-factor authentication settings"

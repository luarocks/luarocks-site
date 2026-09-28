class AdminRock extends require "widgets.admin.page"
  @needs: {"rock"}

  inner_content: =>
    version = @rock\get_version!
    mod = version\get_module!

    h2 ->
      a href: @url_for(@rock), @rock.rock_fname
      text " ("
      a href: @url_for("admin.version", id: version.id), "version admin"
      text ")"

    @field_table @rock, {
      "id"
      {"module", -> @render_model mod}
      {"version", -> @render_model version}
      "arch"
      "rock_fname"
      "rock_key"
      "revision"
      "downloads"
      {"size", -> text @rock.size and @filesize_format(@rock.size) or ""}
      {"sha256", -> code @rock.sha256 or ""}
      {"md5", -> code @rock.md5 or ""}
      "created_at"
      "updated_at"
      {"latest audit", -> @render_latest_audit @rock}
      {"", -> @render_audit_button "rock", @rock}
    }

    h3 "Audits"
    @render_audits_table @rock\get_audits!


lapis = require "lapis"

import
  respond_to
  capture_errors
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_valid from require "lapis.validate"

import
  Modules
  Users
  Followings
  from require "models"

import
  require_login
  from require "helpers.app"

import
  users
  modules
  from require "secrets.toolbox"

_modules = {}
for m in *modules
	_modules[m.id] = m.name

class MoonRocksToolbox extends lapis.Application
  [transfer_endorses: "/toolbox/transfer"]: require_login respond_to {
    GET: =>
      count = 0
      endorsements = {}
      
      for u in *users
      	if u.email == @current_user.email
     	  	endorsements = u.endorsements

      for e in *endorsements
      	name = _modules[tonumber e]
      	if name 
      		m = Modules\find name: name
      		if m
	      		follow = Followings\find source_user_id: @current_user.id, object_id: m.id
	      		if not follow
	      			Followings\create {
		      			source_user_id: @current_user.id
		      			object_type: 1
		      			object_id: m.id
		      		}
	      			count = count+1


      --error("hey"..count)
      --redirect_to: @url_for "user_settings.import_toolbox"
      render: "user_settings.import_toolbox"
  }



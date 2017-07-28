db = require "lapis.db"
import Model from require "lapis.db.model"
import Events from "models"
  
class TimelineEvents extends Model
  @user_timeline: (user) =>
     @@find_all user_id: user.id
  

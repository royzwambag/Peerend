inspect = (require('util')).inspect
eventActions = require('./event-actions/all')
eventTypesRaw = process.env['HUBOT_GITHUB_EVENT_NOTIFIER_TYPES']
eventTypes = []

if eventTypesRaw?
  eventTypes = eventTypesRaw.split(',').map (e) ->
    append = ""

    # append :* to any elements missing it
    if e.indexOf(":") == -1
      append = ":*"

    return "#{e}#{append}"
else
  console.warn("github-repo-event-notifier is not setup to receive any events (HUBOT_GITHUB_EVENT_NOTIFIER_TYPES is empty).")

module.exports = (robot) ->
  robot.router.post "/hubot/gh-repo-events", (req, res) ->
    data = req.body
    eventType = req.headers["x-github-event"]
    robot.logger.debug "github-repo-event-notifier: Received POST to /hubot/gh-repo-events with data = #{inspect data}"
    robot.logger.debug "github-repo-event-notifier: Processing event type: \"#{eventType}\"..."

    try

      filter_parts = eventTypes
        .filter (e) ->
          # should always be at least two parts, from eventTypes creation above
          parts = e.split(":")
          event_part = parts[0]
          action_part = parts[1]

          if event_part != eventType
            return false # remove anything that isn't this event

          if action_part == "*"
            return true # wildcard on this event

          if !data.hasOwnProperty('action')
            return true # no action property, let it pass

          if action_part == data.action
            return true # action match

          return false # no match, fail

      if filter_parts.length > 0
        announceRepoEvent data, eventType, (what) ->
          if Object.keys(what).length > 0
            robot.adapter.customMessage what
      else
        console.log "Ignoring #{eventType}:#{data.action} as it's not allowed."
    catch error
      robot.messageRoom process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"], "Whoa, I got an error: #{error}"
      console.log "Github repo event notifier error: #{error}. Request: #{req.body}"

    res.end ""

announceRepoEvent = (data, eventType, cb) ->
  if eventActions[eventType]?
    eventActions[eventType](data, cb)
  else
    console.log "Received a new #{eventType} event, just so you know."

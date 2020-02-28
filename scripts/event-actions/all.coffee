module.exports =
  pull_request: (data, callback) ->
    msg = {}
    repo = data.repository
    pull_req = data.pull_request
    pull_req_sender = slackUser data.sender.login

    action = data.action

    switch action
      when "assigned"
        pull_req_assignee = slackUser data.assignee.login
        user_exists = userExists pull_req_assignee
        if user_exists
          msg = createMessage(
            repo.full_name,
            pull_req.title,
            pull_req.html_url,
            "Wil je naar de Pull Request van #{pull_req_sender} kijken?",
            pull_req_assignee
          )
      when "review_requested"
        pull_req_reviewer = slackUser data.requested_reviewer.login
        user_exists = userExists pull_req_reviewer
        if data.requested_reviewer.login != data.sender.login && user_exists
          msg = createMessage(
            repo.full_name,
            pull_req.title,
            pull_req.html_url,
            "Wil je naar de Pull Request van #{pull_req_sender} kijken?",
            pull_req_reviewer
          )
  
    callback msg

  pull_request_review: (data, callback) ->
    msg = {}
    repo = data.repository
    review = data.review
    pull_req = data.pull_request
    pull_req_owner = slackUser pull_req.user.login
    pull_req_reviewer = slackUser review.user.login

    user_exists = userExists pull_req_owner
    if pull_req.user.login != review.user.login && user_exists
      msg = createMessage(
        repo.full_name,
        pull_req.title,
        review.html_url,
        "#{pull_req_reviewer} heeft een review geplaatst op je Pull Request",
        pull_req_owner
      )

    callback msg

  pull_request_review_comment: (data, callback) ->
    msg = {}
    repo = data.repository
    comment = data.comment
    pull_req = data.pull_request
    pull_req_owner = slackUser pull_req.user.login
    pull_req_commenter = slackUser comment.user.login
    code_climate = 'codeclimate[bot]'

    user_exists = userExists pull_req_owner
    if pull_req.user.login != comment.user.login && user_exists && pull_req_commenter != code_climate
      msg = createMessage(
        repo.full_name,
        pull_req.title,
        comment.html_url,
        "#{pull_req_commenter} heeft een comment geplaatst op je Pull Request",
        pull_req_owner
      )

    callback msg

slackUser = (username) ->
  for user in process.env['HUBOT_GITHUB_USERS'].split(',')
    do ->
    parts = user.split(":")
    github_user = parts[0]
    slack_user = parts[1]
    if github_user == username
      return slack_user
  username

userExists = (username) ->
  process.env['HUBOT_GITHUB_USERS'].indexOf(username) > -1

createMessage = (repo, title, link, text, room, color) ->
  {
    user: room || process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"],
    text: text,
    attachments: [{
      "color": color || "#3AA3E3",
      "author_name": repo,
      "title": title,
      "title_link": link,
      "text": text
    }] 
  }

buildStatusColor = (state) ->
  switch state
    when "success"
      return "#36a64f"
    when "failed" || "error"
      return "#ff0000"
    when "pending"
      return "#FFA500"

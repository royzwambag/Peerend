module.exports =
  pull_request: (data, callback) ->
    msg = {}
    repo = data.repository
    pull_req = data.pull_request
    pull_req_sender = slackUserInfo(data.sender.login)[0]

    action = data.action

    switch action
      when "assigned"
        pull_req_assignee = slackUserInfo(data.assignee.login)[1]
        user_exists = userExists pull_req_assignee
        if data.requested_reviewer.login != data.sender.login && user_exists
          msg = createMessage(
            repo.full_name,
            pull_req.title,
            pull_req.html_url,
            "Wil je naar de Pull Request van #{pull_req_sender} kijken?",
            pull_req_assignee
          )
      when "review_requested"
        pull_req_reviewer = slackUserInfo(data.requested_reviewer.login)[1]
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
    pull_req_owner = slackUserInfo(pull_req.user.login)[1]
    pull_req_reviewer = slackUserInfo(review.user.login)[0]

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
    pull_req_owner_id = slackUserInfo(pull_req.user.login)[1]
    pull_req_commenter = slackUserInfo(comment.user.login)[0]
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

slackUserInfo = (username) ->
  for user in process.env['HUBOT_GITHUB_USERS_AND_IDS'].split(',')
    do ->
    parts = user.split(":")
    github_user = parts[0]
    name = parts[1]
    id = parts[2]
    if github_user == username
      return [name, id]
  [username, null]

userExists = (username) ->
  process.env['HUBOT_GITHUB_USERS_AND_IDS'].indexOf(username) > -1

createMessage = (repo, title, link, text, room, color) ->
  {
    channel: room, 
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

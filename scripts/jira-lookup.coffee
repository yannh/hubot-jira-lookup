# Description:
#   Jira lookup when issues are heard
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_LOOKUP_USERNAME
#   HUBOT_JIRA_LOOKUP_PASSWORD
#   HUBOT_JIRA_LOOKUP_URL
#   HUBOT_JIRA_LOOKUP_IGNORE_USERS (optional, format: "user1|user2", default is "jira|github")
#
# Commands:
#   None
#
# Author:
#   Matthew Finlayson <matthew.finlayson@jivesoftware.com> (http://www.jivesoftware.com)
#   Benjamin Sherman  <benjamin@jivesoftware.com> (http://www.jivesoftware.com)
#   Dustin Miller <dustin@sharepointexperts.com> (http://sharepointexperience.com)

module.exports = (robot) ->

  ignored_users = process.env.HUBOT_JIRA_LOOKUP_IGNORE_USERS
  if ignored_users == undefined
    ignored_users = "jira|github"

  robot.hear /\b[a-zA-Z]{2,5}-[0-9]{1,5}\b/, (msg) ->

    return if msg.message.user.name.match(new RegExp(ignored_users, "gi"))

    issue = msg.match[0]
    user = process.env.HUBOT_JIRA_LOOKUP_USERNAME
    pass = process.env.HUBOT_JIRA_LOOKUP_PASSWORD
    url = process.env.HUBOT_JIRA_LOOKUP_URL
    auth = 'Basic ' + new Buffer(user + ':' + pass).toString('base64')
    robot.http("#{url}/rest/api/latest/issue/#{issue}")
      .headers(Authorization: auth, Accept: 'application/json')
      .get() (err, res, body) ->
        try
          json = JSON.parse(body)
          json_summary = ""
          if json.fields.summary
            unless json.fields.summary is null or json.fields.summary.nil? or json.fields.summary.empty?
              json_summary = json.fields.summary
          json_assignee = ""
          if json.fields.assignee
            unless json.fields.assignee is null or json.fields.assignee.nil? or json.fields.assignee.empty?
              unless json.fields.assignee.name.nil? or json.fields.assignee.name.empty?
                json_assignee += json.fields.assignee.name
          json_status = ""
          if json.fields.status
            unless json.fields.status is null or json.fields.status.nil? or json.fields.status.empty?
              unless json.fields.status.name.nil? or json.fields.status.name.empty?
                json_status += json.fields.status.name
          msg.send "<a href=\"#{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}\">#{json.key}</a>: #{json_summary} (<strong>#{json_status}</strong> - Assigned to <a href=\"#{process.env.HUBOT_JIRA_LOOKUP_URL}/secure/ViewProfile.jspa?name=#{json_assignee}\">{json_assignee}</a>)\n"
        catch error
          msg.send "*sinister laugh*"

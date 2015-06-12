# Description:
#   Manage your links. Links get stored in the robot brain.
#
# Commands:
#   hubot link add <url> as <description> - add a url to the robot brain
#   hubot link find <description> - find a link by description
#   hubot link list - List all of the links that are being tracked
#   hubot link delete <description> - delete a link by description
#
# Authors:
#   Jason Poon <github@jasonpoon.ca>
#   with inspiration from bookmark.coffee

module.exports = (robot) ->

  # link <url> as <description>
  robot.respond /link add (.+) as (.+)/i, (msg) ->
    url = msg.match[1]
    description = msg.match[2]

    urlPattern = /// ^          # begin of line
       (https?:\/\/)?           # optional http/https
       ([\w-]+(\.[\w-]+)+\.?)   # domain name with at least two components, allow trailing dot
       $ ///i                   # end of line and ignore case

    match = url.match urlPattern
    if !url.match urlPattern
      msg.reply "Is that a valid URL? Should be something like 'domain.tld'."
    else
      bookmark = new Bookmark url, description
      link = new Link robot
  
      link.add bookmark, (err, message) ->
        if err?
          msg.reply "I have a vague memory of hearing about that link sometime in the past."
        else
          msg.reply "I've stuck that link into my robot brain." 
 
  # link find <description> 
  robot.respond /link find (.+)/i, (msg) ->
    description = msg.match[1]
    link = new Link robot
    
    link.find description, (bookmarks) ->
        message = "Found " + bookmarks.length + " link(s)"
        if bookmarks.length > 0
            message += ":\n\n"
        for bookmark in bookmarks
            message += bookmark.description + " (" + bookmark.url + ")\n"
        msg.send message
  
  # link list
  robot.respond /link list/i, (msg) ->
    link = new Link robot
    
    link.list (err, message) ->
      if err?   
        msg.reply "Links? What links? I don't remember any links."       
      else
        msg.reply message

# Classes
class Url
  constructor: (robot) ->
    robot.brain.data.urls ?= []
    @urls_ = robot.brain.data.urls

  all: (url) ->
    if url
      @urls_.push url
    else
      @urls_

  add: (url, callback) ->
    if url in @all()
      callback "Url already exists"
    else
      @all url
      callback null, "Url added"

class Bookmark
  constructor: (url, description) ->
    @url = url
    @description = description

class Link
  constructor: (robot) ->
    robot.brain.data.links ?= []
    @links_ = robot.brain.data.links

  all: (bookmark) ->
    if bookmark
      @links_.push bookmark
    else
      @links_

  add: (bookmark, callback) ->
    result = []
    @all().forEach (entry) ->
      if entry
        if entry.url is bookmark.url
          result.push bookmark
    if result.length > 0
      callback "Bookmark already exists"
    else
      @all bookmark
      callback null, "Bookmark added"    

  list: (callback) ->
    if @all().length > 0
      resp_str = "These are the links I'm remembering:\n\n"
      for bookmark in @all()
        if bookmark
          resp_str += bookmark.description + " (" + bookmark.url + ")\n"
      callback null, resp_str    
    else
      callback "No bookmarks exist"

  find: (description, callback) ->
    result = []
    @all().forEach (bookmark) ->
      if bookmark && bookmark.description
        if RegExp(description, "i").test bookmark.description
          result.push bookmark
    callback result

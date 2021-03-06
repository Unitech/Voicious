###

Copyright (c) 2011-2013  Voicious

This program is free software: you can redistribute it and/or modify it under the terms of the
GNU Affero General Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

###

do () ->
    showdownExt = (converter) ->
        [
            {
                type   : 'lang'
                filter : (text) ->
                    text.replace /<?(http|https|ftp)\:\/\/([^\s]+)>?/, "[$1://$2]($1://$2)"
            }
            {
                type   : 'output'
                filter : (source) ->
                    source.replace /<a href="(.+)">(.+)<\/a>/, '<a href="$1" target="_blank">$2</a>'
            }
        ]
    if window? and window.Showdown and window.Showdown.extensions
        window.Showdown.extensions.voicious = showdownExt

class TextChat extends Module
    # Init the text chat window and the callbacks in the event manager.
    constructor     : (emitter) ->
        super emitter
        do @appendHTML

        @markdown     = new Showdown.converter { extensions : ['voicious'] }
        @jqForm       = ($ '#chatForm > form')
        @jqMessageBox = ($ '#chatContent > ul')
        @jqInput      = @jqForm.children 'textarea'

        @scrollPane   = @jqMessageBox.jScrollPane { horizontalDragMaxWidth: 0 }
        @scrollPane   = @jqMessageBox.data 'jsp'

        @jqInput.on 'keypress', (event) =>
            if event.keyCode is 13 and not event.shiftKey
                do event.preventDefault
                @jqInput.trigger 'submit'

        @jqForm.submit (event) =>
            do event.preventDefault
            message = do @jqInput.val
            message = message.replace /\n/g, '<br />'
            @jqInput.val ''
            # We check if it's a command or a message
            command = message.match(/^\/([a-zA-Z ]+)/)
            if command?
                @sendCommand command
            else
                @sendMessage message

        $(window).resize () =>
            do @scrollPane.reinitialise
        
        me =
            name : 'me'
            callback : @me
        @emitter.trigger 'cmd.register', me
        
        @emitter.on 'chat.message', (event, data) =>
            @addMessage data.message
        @emitter.on 'chat.error', (event, data) =>
            @addServerMessage data
        @emitter.on 'chat.info', (event, data) =>
            @addServerMessage data
        @emitter.on 'chat.me', (event, data) =>
            @addMeMessage data
        @emitter.on 'peer.create', (event, data) =>
            @emitter.trigger 'chat.error', { text : "#{data.name} arrives in the room." }
        @emitter.on 'peer.remove', (event, data) =>
            @emitter.trigger 'chat.error', { text : "#{data.name} leaves the room. (#{data.reason})" }

    appendHTML      : () ->
        html = ($ '<div class="module fill-height color-one" id="textChat">
                   <div class="frame">
                       <div id="chatContent">
                            <ul></ul>
                       </div>
                       <div id="chatForm">
                           <form>
                                <span id="descriptionTC">press ENTER to post</span>
                                <textarea type="text"></textarea>' +
                                # Wait for i18n
                                #<input type="text" data-step="5" data-intro="" data-position="top"></input>
                          '</form>
                       </div>
                   </div>
                   </div>'
        )
        html.appendTo "#modArea"

    # Update the text chat with a new message.
    update          : (message) =>
        @addMessage message

    # Send the command to the command Manager
    sendCommand     : (command) =>
        command =
            cmd : command[1]
            from : window.Voicious.currentUser.name
        @emitter.trigger 'chat.cmd', command

    # Send the new message to the guests.
    sendMessage     : (message) =>
        if message? and message isnt ""
            message =
                text : message
                from : window.Voicious.currentUser.name
            @emitter.trigger 'message.sendtoall', message
            @addMessage message

    # Create a new message element and append it to @jqMessageBox
    newMessageElem : (message) =>
        d             = new Date
        jqNewMetadata = ($ '<div>', { class : 'chatmetadata' })
        jqNewAuthor   = ($ '<span>', { class : 'fontlightblue', rel : do d.getTime }).text message.from
        jqNewTime     = ($ '<span>', { class : 'time' }).text ' at ' + ((do d.toTimeString).substr 0, 5)
        (jqNewMetadata.append jqNewAuthor).append jqNewTime
        jqNewMessage  = ($ '<div>', { class : 'chatmessage' }).html message.text
        (do @scrollPane.getContentPane).append (($ '<li>').append jqNewMetadata).append jqNewMessage

    # Add a new message to the text chat window.
    addMessage      : (message) =>
        message.text  = @markdown.makeHtml message.text
        jqLastMessage = do (@jqMessageBox.find 'li').last
        if jqLastMessage[0]?
            d          = new Date
            lastAuthor = do ((jqLastMessage.children '.chatmetadata').children 'span').first
            diffTime   = do d.getTime - lastAuthor.attr 'rel'
            if do lastAuthor.text is message.from and diffTime < 30000
                #(jqLastMessage.children '.chatmessage').append ($ '<br>')
                (jqLastMessage.children '.chatmessage').append message.text
                lastAuthor.attr 'rel', do d.getTime
            else
                jqLastMessage.append '<div id="tcSeparator"></div>'
                @newMessageElem message
        else
            @newMessageElem message
        do @scrollPane.reinitialise
        @scrollPane.scrollToPercentY 100, no

    # Add an information message to the text chat window.
    addServerMessage    : (message) =>
        jqLastMessage = do (@jqMessageBox.find 'li').last
        d = new Date
        jqNewMsg  = ($ '<div>', { class : 'blueduckturquoise italic' }).html message.text
        jqNewTime   = ($ '<span>', { class : 'time' }).text ' at ' + ((do d.toTimeString).substr 0, 5)
        jqNewMsg.append jqNewTime
        if jqLastMessage[0]?
            jqLastMessage.append '<div id="tcSeparator"></div>'
        (do @scrollPane.getContentPane).append ($ '<li>').append jqNewMsg
        do @scrollPane.reinitialise
        @scrollPane.scrollToPercentY 100, no

    # Add an action message to the text chat window
    addMeMessage        : (action) =>
        jqLastMessage = do (@jqMessageBox.find 'li').last
        d = new Date
        jqNewMsg  = ($ '<div>', { class : 'blueduckturquoise' }).html action.text
        jqNewTime   = ($ '<span>', { class : 'time' }).text ' at ' + ((do d.toTimeString).substr 0, 5)
        jqNewMsg.append jqNewTime
        if jqLastMessage[0]?
            jqLastMessage.append '<div id="tcSeparator"></div>'
        (do @scrollPane.getContentPane).append ($ '<li>').append jqNewMsg
        do @scrollPane.reinitialise
        @scrollPane.scrollToPercentY 100, no
    
    me                  : (user, data) =>
        if data[1]?
            action = (data.slice 1).join " "
            text = "#{user} #{action}"
            message = { type : 'cmd.me',  params : { text : text } }
            @emitter.trigger 'message.sendtoall', message
            @addMeMessage message.params
        else
            message = { text : "me: usage: /me [action]" }
            @addServerMessage message

if window?
    window.TextChat     = TextChat

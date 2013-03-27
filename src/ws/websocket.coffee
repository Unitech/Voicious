###

Copyright (c) 2011-2012  Voicious

This program is free software: you can redistribute it and/or modify it under the terms of the
GNU Affero General Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

###

Http    = require 'http'
Ws      = (require 'ws').Server
Request = require 'request'

Config = require '../common/config'

class Websocket
    constructor : () ->
        @socks = { }

    onConnection : (sock) =>
        that = @
        sock.onmessage = (message) ->
            message = JSON.parse message.data
            if message.type is 'authenticate'
                that.validateSock message.params.uid, message.params.rid, @

    validateSock : (uid, rid, sock) =>
        Request.get "#{Config.Restapi.Url}/room/#{rid}", (e, r, body) =>
            if not e?
                Request.get "#{Config.Restapi.Url}/user/#{uid}", (e, r, body) =>
                    body = JSON.parse body
                    if not e? and body.id_room is rid
                        @acceptSock body.id, rid, body.name, sock

    acceptSock : (uid, rid, name, sock) =>
        that             = @
        sock.rid         = rid
        sock.uid         = uid
        sock.onmessage   = (message) ->
            that.onmessage @, message
        @send sock, { type : 'authenticated' }
        if not @socks[rid]?
            @socks[rid] = { }
        else
            peers = []
            for _uid of @socks[rid]
                @send @socks[rid][_uid].sock, { type : 'peer.create' , params : { id : uid , name : name } }
                peers.push { id : _uid , name : @socks[rid][_uid].name }
            @send sock, { type : 'peer.list' , params : { peers : peers } }
        @socks[rid][uid] = { sock : sock , name : name }

    onmessage : (sock, message) =>
        message = JSON.parse message.data
        switch message.type
            when 'forward' then do () =>
                s = @socks[sock.rid][message.params.to]
                if s?
                    message.params.data.params.from = sock.uid
                    @send @socks[sock.rid][message.params.to].sock, message.params.data

    send : (sock, message) =>
        sock.send JSON.stringify message

    start : () =>
        @server = new Ws {
            server : (Http.createServer (req, res) ->).listen Config.Websocket.Port, () =>
                console.log "Server ready on port #{Config.Websocket.Port}"
        }
        @server.on 'connection', @onConnection

do (new Websocket).start

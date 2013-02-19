###

Copyright (c) 2011-2012  Voicious

This program is free software: you can redistribute it and/or modify it under the terms of the
GNU Affero General Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

###

class Room
    constructor         : () ->
        @userList       = new UserList
        @networkManager = NetworkManager '192.168.1.13', 4244
        do @configureEvents

    configureEvents     : () =>
        EventManager.addEvent "fillUsersList", (users) =>
            @userList.fill users
        EventManager.addEvent "updateUserList", (user, event) =>
            @userList.update user, event

    joinConference      : () =>
        options =
            video       : '#localVideo'
            onsuccess   : (stream) =>
                window.localStream          = stream
                @networkManager.negociatePeersOffer stream
                $('#joinConference').attr "disabled", "disabled"
            onerror     : (e) =>
        do $(options.video).show

        WebRTC.getUserMedia(options)

    start               : () =>
        do @networkManager.connection
        $('#joinConference').click () =>
            do $('#notActivate').hide
            @joinConference()

$(document).ready ->
    $('#videos').delegate 'li.thumbnail', 'click', () ->
        prevCam = $('#mainCam video')
        prevId = -1
        newId = $(this).find('video').attr('id')
        if prevCam
            prevId = prevCam.attr 'id'
        if newId isnt prevId
            do prevCam.remove
            newCam = $(this).find('video').clone()
            newCam.removeClass 'thumbnailVideo'
            newCam.addClass 'mainCam'
            $('#mainCam').append newCam
    if do WebRTC.runnable == true
        room = new Room
        do room.start
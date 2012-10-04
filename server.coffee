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

http = require('http')
url = require('url')
router = require('./router')

start = (port) ->
    onRequest = (request, response) ->
        try
                pathname = url.parse(request.url).pathname
                template = router.route(pathname, request, response)
                if template.template?
                    response.writeHead(200, {"Content-Type": "text/html"})
                    response.write(template.template)
                    response.end()
        catch e
                response.writeHead(200, {"Content-Type": "text/html"})
                response.write(e.template)
                response.end()

    http.createServer(onRequest).listen(port)
    console.log "Server ready on port #{port}"

exports.start = start

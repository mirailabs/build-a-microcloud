const http = require('http');

http.createServer(function(req, resp) {
  console.log('Received request for URL: ' + req.url);
  resp.writeHead(200);
  resp.end('Hello, World!\n');
}).listen(8080);

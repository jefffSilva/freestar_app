const http = require("http");

const port = Number(process.env.PORT || 8080);

const server = http.createServer((_req, res) => {
  res.statusCode = 200;
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.end("Hello from Freestar Cloud Run\n");
});

server.listen(port, "0.0.0.0", () => {
  // eslint-disable-next-line no-console
  console.log(`listening on ${port}`);
});

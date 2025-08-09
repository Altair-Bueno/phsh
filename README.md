# phsh

> Better than PHP, use Bash!

**phsh** is a ~~production ready~~ HTTP web framework written in Bash, inspired
by [bahamas10/bash-web-server](https://github.com/bahamas10/bash-web-server).
The name "phsh" is a playful pun on PHP, as it is written in Bash and is much
more enjoyable to use than PHP.

Unlike bahamas10's implementation, **phsh** is not written in pure Bash just for
the sake of simplicity.

## Motivation

The main motivation behind phsh is to explore how much we can push Bash as a web
server platform. While bahamas10/bash-web-server proved that it is possible, it
was limited by the constraints of pure Bash. **phsh** aims to demonstrate how
far Bash can be pushed by creating a fully featured HTTP framework that is still
hackable and extensible.

## Requirements

To use **phsh**, you need:

- **Bash** (preferably GNU Bash)
- **bash-builtins** (for socket handling, e.g., the `accept` builtin)
- Standard GNU/BSD utilities (e.g., `file`, `realpath`)

## Installation & Usage

You can use **phsh** by cloning the repository and sourcing the required files
in your Bash scripts.

### As a Submodule

To add **phsh** to your project as a submodule:

```sh
git submodule add https://github.com/yourusername/phsh.git phsh
```

Then, in your scripts, source the main framework and any middlewares you need:

```bash
source "phsh/phsh.bash"
source "phsh/middlewares/accept.bash"
source "phsh/middlewares/content-type.bash"
```

### Running an Example

You can run any of the examples in the [`examples`](phsh/examples) directory.
For example:

```sh
bash phsh/examples/api-router.bash
```

## Examples

The [`examples`](phsh/examples) directory contains several ready-to-use scripts
demonstrating how to use **phsh**:

- **api-router.bash**: A RESTful API router that responds to
  `/api/v1/hello?name=...` with a JSON greeting. Shows how to use routing and
  middleware.
- **file-server.bash**: Serves static files from the current directory, with
  proper MIME types and path traversal protection. Demonstrates file serving and
  security practices.
- **crash.bash**: Demonstrates error handling. Intentionally crashes to show how
  the server responds with a 500 error even when an error occurs in the handler.

Explore these examples to learn how to build your own handlers and middleware.

## API Reference

**phsh** exposes several variables and functions for handling HTTP requests and
responses. All variables starting with `PHSH_` are part of the API:

### Request Variables

- `PHSH_REQUEST_VERB`: HTTP method (e.g., `GET`, `POST`)
- `PHSH_REQUEST_PATH`: Full request path (e.g., `/api/v1/hello?name=world`)
- `PHSH_REQUEST_VERSION`: HTTP version (e.g., `HTTP/1.0`, `HTTP/1.1`)
- `PHSH_REQUEST_HEADERS`: Associative array of request headers
- `PHSH_REQUEST_BODY`: Request body (if any)
- `PHSH_REQUEST_PATHNAME`: Path without query/hash, URL-decoded (e.g.,
  `/api/v1/hello` or `/`)
- `PHSH_REQUEST_HASH`: Hash fragment (if present, e.g., `#section`)
- `PHSH_REQUEST_SEARCH`: Query string (if present, e.g., `?name=world`)
- `PHSH_REQUEST_SEARCH_PARAMS`: Associative array of query parameters, URL
  decoded (if present)
- `PHSH_REQUEST_IP`: Remote IP address of the client (e.g., `1.1.1.1`)

### Response Variables

- `PHSH_REPLY_STATUS_CODE`: HTTP status code (default: `200`)
- `PHSH_REPLY_HEADERS`: Associative array of response headers
- `PHSH_REPLY_BODY`: Response body (for in-memory responses)
- `PHSH_REPLY_STREAM`: Path to file to stream as response body (for large files)

> Note: If both `PHSH_REPLY_BODY` and `PHSH_REPLY_STREAM` are set, the body will
> be ignored, and the file will be streamed instead.

### Logging

- `PHSH_LOG_LEVEL`: Controls verbosity (`ERROR`, `WARN`, `INFO`, `DEBUG`)

### Functions

- `phsh-http-serve`: Main server loop.
- `phsh-url-encode`, `phsh-url-decode`: URL encoding/decoding utilities
- `phsh-log-error`, `phsh-log-warn`, `phsh-log-info`, `phsh-log-debug`,
  `phsh-log`: Logging functions for different log levels

## Middleware

You can extend **phsh** with middleware. Some are provided in the `middlewares`
directory:

- **accept.bash**: Handles HTTP Accept headers
- **content-type.bash**: Sets Content-Type headers

## Writing Your Own Handler

A handler is a Bash function that sets the appropriate `PHSH_REPLY_*` variables.
For example:

```bash
function my-handler {
    PHSH_REPLY_STATUS_CODE=200
    PHSH_REPLY_HEADERS[content-type]="text/plain"
    PHSH_REPLY_BODY="Hello, world!"
}
phsh-http-serve -c my-handler
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Pull requests and issues are welcome!

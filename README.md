# Trip Reporter

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Usage](#usage)

## About <a name = "about"></a>

Fills AHCCCS trip report PDF forms from a JSON object. 

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

### Prerequisites

The project runs under docker. A docker-compose file is provided to easily start the development environment. 

Running tests via `test/run_test.sh` requires use of [jq](https://stedolan.github.io/jq/).

### Installing

```
docker-compose up
```

## Usage <a name = "usage"></a>

To fill a trip report post the data to `/api/fill_form`

```
curl -X "POST" "http://localhost:4567/api/fill/ahcccs" \
     -H 'Content-Type: application/json' \
     -d $'{"key": "value"}'
```

See [test/run_test.sh](/test/run_test.sh) for all available keys.


A success will return a code 200 with a JSON object containing Base64 encoded PDF:

```
{
  "pdf: "base64 content"
}
```

Errors return the appropriate code (500, 404, etc) with a description of the error:
```
{
  "error: "File not Found"
}
```
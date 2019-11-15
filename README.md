# Trip Reporter

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Usage](#usage)

## About <a name = "about"></a>

Fills [AHCCCS trip report](https://www.azahcccs.gov/PlansProviders/CurrentProviders/NEMTproviders.html) PDF forms from a JSON object. A trip report PDF with added form fields is included in the image. [PDFtk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/) is used to fill the form fields.

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

The project runs under docker. A docker-compose file is provided to easily start the development environment.

### Installing

```
docker-compose up
```

A simple [test script](/test/run_test.sh) is included that will output `result.pdf` in your current working directory.


## Usage <a name = "usage"></a>

To fill a trip report post the data to `/api/ahcccs/v2019/fill`

```
curl -X "POST" "http://localhost:4567/api/ahcccs/v2019/fill" \
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

Errors return the appropriate code (500, 404, etc) with a description of the error(s):
```
{
  "error": [
    "TripReporter::OverlayError - /tmp/d20191112-1-1j76cvt/signature.png error: improper image header `/tmp/d20191112-1-1j76cvt/signature.png' @ error/png.c/ReadPNGImage/4092"
  ]
}
```
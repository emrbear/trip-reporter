# Trip Reporter

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Usage](#usage)

## About <a name = "about"></a>

Fills AHCCCS trip report PDF forms from a JSON object. 

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [deployment](#deployment) for notes on how to deploy the project on a live system.

### Prerequisites

The project runs under docker. A docker-compose file is provided to easily start the development environment. 

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

Available keys: 

```
{
  "multiple_members_drop_no": Bool,
  "pickup_am_1": String,
  "dropoff_time_1": "10String,
  "dropoff_pm_5": String,
  "reason_for_visit_2": String,
  "vehicle_make_color": "String,
  "pickup_address_4": String,
  "dropoff_odometer_4": String,
  "dropoff_miles_6": String,
  "dropoff_pm_2": String,
  "multiple_stops_4": String,
  "pickup_odometer_5": String,
  "pickup_pm_6": String,
  "roundtrip_2": String,
  "signature_date": String,
  "name_of_escort_3": String,
  "pickup_time_5": "5String,
  "relationship_4": "String,
  "round_trip_5": String,
  "dropoff_am_4": String,
  "dropoff_address_2": String,
  "dropoff_time_5": "15String,
  "vehicle_other_note": "String,
  "pickup_address_5": String,
  "dropoff_am_1": String,
  "multiple_stops_5": String,
  "pickup_am_2": String,
  "pickup_time_2": "2String,
  "page_2_of": String,
  "dob_2": "12-12String,
  "multiple_members_no": Bool,
  "name_of_escort_4": String,
  "date": "12-12String,
  "multiple_members_drop_yes": Bool,
  "vehicle_other": Bool,
  "pickup_odometer_1": String,
  "dropoff_odometer_2": String,
  "pickup_pm_1": String,
  "pickup_address_6": String,
  "pickup_odometer_6": String,
  "finger_print": String,
  "multiple_stops_6": String,
  "reason_for_visit_5": String,
  "signature": String,
  "relationship_1": String,
  "vehicle_taxi": Bool,
  "dropoff_time_2": "12String,
  "member_name_2": String,
  "trip_miles_1": String,
  "multiple_members_yes": Bool,
  "pickup_am_3": String,
  "dropoff_address_3": String,
  "dropoff_pm_6": String,
  "company_address": String,
  "ahcccs_id_2": String,
  "dropoff_pm_3": String,
  "dropoff_miles_3": String,
  "relationship_5": "String,
  "pickup_pm_2": String,
  "dropoff_time_6": "16String,
  "page_1": String,
  "reason_for_visit_3": String,
  "pickup_odometer_2": String,
  "dropoff_am_5": String,
  "dropoff_odometer_5": String,
  "one_way_1": String,
  "driver_signature": String,
  "pickup_time_4": "4String,
  "round_trip_6": String,
  "round_trip_3": String,
  "drivers_name": String,
  "dropoff_am_2": String,
  "pickup_am_4": String,
  "one_way_2": String,
  "dropoff_miles_5": String,
  "vehicle_number": String,
  "pickup_time_1": "1String,
  "one_way_3": String,
  "signer": String,
  "dropoff_address_4": String,
  "reason_for_vist_6": String,
  "relationship_2": String,
  "member_name": String,
  "pickup_pm_3": String,
  "dropoff_time_3": "13String,
  "one_way_4": String,
  "vehicle_bus": Bool,
  "one_way_5": String,
  "unable_to_sign": Bool,
  "reason_for_visit_1": String,
  "dropoff_odometer_3": String,
  "pickup_am_5": String,
  "pickup_odometer_3": String,
  "one_way_6": String,
  "relationship_6": "String,
  "page_2": String,
  "dob": "12-12String,
  "dropoff_pm_4": String,
  "vehicle_stretcher": Bool,
  "page_1_of": String,
  "pickup_pm_4": String,
  "dropoff_pm_1": String,
  "pickup_address_1": String,
  "multiple_stops_1": String,
  "dropoff_address_5": String,
  "pickup_time_6": "6String,
  "escort_2": String,
  "dropoff_am_6": String,
  "mailing_address": String,
  "round_trip_4": String,
  "dropoff_am_3": String,
  "pickup_time_3": "3String,
  "pickup_am_6": String,
  "vehicle_wheelchair_van": Bool,
  "escort_5": String,
  "relationship_3": "String,
  "dropoff_miles_2": String,
  "dropoff_odometer_1": String,
  "multiple_stops_2": String,
  "pickup_address_2": String,
  "dropoff_odometer_6": String,
  "dropoff_time_4": "14String,
  "escort_6": String,
  "pickup_odometer_4": String,
  "reason_for_visit_4": String,
  "name_of_escort_1": String,
  "additional_info": String,
  "pickup_pm_5": String,
  "ahcccs_id": String,
  "dropoff_address_1": String,
  "pickup_address_3": String,
  "dropoff_miles_4": String,
  "dropoff_address_6": String,
  "multiple_stops_3": String
```

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
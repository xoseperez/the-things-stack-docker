# Changelog

## 1.2.1 (2024-03-28)

* Updated to Stack 3.29.2

## 1.2.0 (2024-03-20)

* Updated to Stack 3.29.1
* Code clean up
* Faster boot time (checks for PostgreSQL connection)

## 1.1.8 (2024-02-09)

* Fix static image on docker-compose.yml file

## 1.1.7 (2023-12-18)

* Updated to Stack 3.28.1

## 1.1.6 (2023-09-18)

* Updated to Stack 3.27.2

## 1.1.5 (2022-12-29)

* Added console.ui.dcs section to ttn-lw-stack-docker (thanks to Davis McCoy for the heads up)

## 1.1.4 (2022-12-29)

* Updated to Stack 3.23.1

## 1.1.3 (2022-12-07)

* Updated to Stack 3.23.0

## 1.1.2 (2022-09-29)

* Updated to Stack 3.21.2

## 1.1.1 (2022-08-24)

* Fix common name in certificate creation (might need to recreate certs, see README)
* Split reset.sh into reset_db.sh and reset_certs.sh
* Added TTS_PORT

## 1.1.0 (2022-08-12)

* Updated to Stack 3.21.0
* Fix upgrade from previous versions

## 1.0.8 (2022-08-01)

* Updated to Stack 3.20.2

## 1.0.7 (2022-06-15)

* Fix forwarding rules
* Disable PB forwarding if not connected

## 1.0.6 (2022-06-10)

* Fix CLI credentials cache accros reboots

## 1.0.5 (2022-06-05)

* Option to enable CLI auto-login

## 1.0.4 (2022-05-31)

* Based on The Things Stack v3.19.2

## 1.0.3 (2022-05-18)

* Based on The Things Stack v3.19.1
* Updated Redis to version 7.0.0
* Updated Postgres to version 14.3
* Fixed support for AMD64 architecture
* Added balena.yml file

## 1.0.2 (2022-01-21)

* Folder refactor
* Added get_certificate.sh tool

## 1.0.1 (2022-01-21)

* Added support for Balena dashboard through the API
* Added metadata to the image
* Improced build system

## 1.0.0 (2021-07-02)

* Based on The Things Stack v3.13.2

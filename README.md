# The Things Stack LoRaWAN Network Server

![The Things Stack CE for Raspberry Pi](https://raw.githubusercontent.com/xoseperez/the-things-stack-docker/master/resources/logo_small.png)

## Introduction

This project deploys the The Things Stack LoRaWAN Network Server (Open Source Edition) on a PC, a Raspberry Pi or equivalent SBC using docker.

Main features:

* Supports for AMD64 (x86_64), ARMv8 and ARMv7 architectures.
* Automatically creates a configuration file based on environment variables
* Creates a self signed certificate
* Configures the identity database
  * Initializes it
  * Creates an admin
  * Creates oauth clients for the CLI and the console
* Support for Packet Broker

Based on [The Things Stack](https://hub.docker.com/r/thethingsnetwork/lorawan-stack/) image.

This project is available on Docker Hub (https://hub.docker.com/r/xoseperez/the-things-stack) and GitHub (https://github.com/xoseperez/the-things-stack-docker).

This is a Work In Progress. It is **not meant for production environments** but it should work just fine for local (LAN) deployments.

## Requirements

### Hardware

As long as the host can run docker containers, the The Things Stack service can run on:

* AMD64: most PCs out there
* ARMv8: Raspberry Pi 3/4, 400, Compute Module 3/4, Zero 2 W,...
* ARMv7: Raspberry Pi 2

> **NOTE**: you will need an OS in the host machine, for some SBC like a Raspberry Pi that means and SD card with an OS (like Rasperry Pi OS) flashed on it.

### Software

If you are going to use docker to deploy the project, you will need:

* An OS running your host (Linux or MacOS for AMD64 systems, Raspberry Pi OS, Ubuntu OS for ARM,...)
* Docker (and optionally docker-compose) on the machine (see below for installation instructions)
* [balenaEtcher](https://balena.io/etcher) to burn the OS image on the SD card or eMMC for SBC if you have not already done so

If you are going to use this image with Balena, you will need:

* A balenaCloud account ([sign up here](https://dashboard.balena-cloud.com/))


### Network

Even thou they are not necessary, you may want to have:

* a static IP for the device (either in the device itself or using a DHCP lease on your router)
* a domain (or a subdomain of a domain you already have) pointing to the device

Check the `Configuring the domain` section below for different options to fulfull these two options.


## Deploy

### Deploy using docker compose

You can use the next `docker-compose.yml` file to configure and run your instance of The Things Stack.

```
version: '3.7'

volumes:
    redis: 
    postgres:
    stack-blob:
    stack-data:

services:

  postgres:
    image: postgres:14.3-alpine3.15
    container_name: postgres
    restart: unless-stopped
    environment:
        - POSTGRES_PASSWORD=root
        - POSTGRES_USER=root
        - POSTGRES_DB=ttn_lorawan
    volumes:
        - 'postgres:/var/lib/postgresql/data'
    ports:
        - "127.0.0.1:5432:5432"
    
  redis:
    image: redis:7.0.0-alpine3.15
    container_name: redis
    command: redis-server --appendonly yes
    restart: unless-stopped
    volumes:
        - 'redis:/data'
    ports:
        - "127.0.0.1:6379:6379"
  
  stack:
    image: xoseperez/the-things-stack:latest
    container_name: stack
    restart: unless-stopped
    depends_on:
        - redis
        - postgres
    volumes:
        - 'stack-blob:/srv/ttn-lorawan/public/blob'
        - 'stack-data:/srv/data'
    environment:
        TTS_DOMAIN: lns.example.com      # set this to the IP or domain name of the host you will be using to access the stack
        TTN_LW_BLOB_LOCAL_DIRECTORY: /srv/ttn-lorawan/public/blob
        TTN_LW_REDIS_ADDRESS: redis:6379
        TTN_LW_IS_DATABASE_URI: postgres://root:root@postgres:5432/ttn_lorawan?sslmode=disable
        CLI_AUTO_LOGIN: "false"
    labels:
        io.balena.features.balena-api: '1'

    ports:
    
        - "80:1885"
        - "443:8885"
    
        - "1881:1881"
        - "1882:1882"
        - "1883:1883"
        - "1884:1884"
        - "1885:1885"
        - "1887:1887"
    
        - "8881:8881"
        - "8882:8882"
        - "8883:8883"
        - "8884:8884"
        - "8885:8885"
        - "8887:8887"
    
        - "1700:1700/udp"
  ```

Modify the `TTS_DOMAIN` environment variable to match your setup. 

### One-click deploy via [Balena Deploy](https://www.balena.io/docs/learn/deploy/deploy-with-balena-button/)

Running this project is as simple as deploying it to a balenaCloud application. You can do it in just one click by using the button below:

[![](https://www.balena.io/deploy.png)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/xoseperez/the-things-stack-docker)

Follow instructions, click Add a Device and flash an SD card with that OS image dowloaded from balenaCloud. Enjoy the magic 🌟Over-The-Air🌟!

### In-control deploy via [Balena-Cli](https://www.balena.io/docs/reference/balena-cli/)

If you are a balena CLI expert, feel free to use balena CLI. This option lets you configure in detail some options, like adding new services to your deploy or configure de DNS Server to use.

- Sign up on [balena.io](https://dashboard.balena.io/signup)
- Create a new fleet on balenaCloud.
- Add a new device and download the image of the BalenaOS it creates.
- This is the moment to configure the DNS server in the BalenaOS if required. See the `Configuring the domain` section  below.
- Burn and SD card (if using a Pi), connect it to the device and boot it up.

While the device boots (it will eventually show up in the Balena dashboard) we will prepare de services:

- Clone this repository to your local workstation. Don't forget to update the submodules.
```
cd ~/workspace
git clone https://github.com/xoseperez/the-things-stack-docker
cd the-things-stack-docker
```
- Using [Balena CLI](https://www.balena.io/docs/reference/cli/), push the code with `balena push <fleet-name>`
- See the magic happening, your device is getting updated 🌟Over-The-Air🌟!

## Log in

Point your browser to the first local IP of the device or to the domain name (if you have defined one) using HTTPS and use the default credentials (admin/changeme) to log in as administrator.

## Details

### Resetting values

Certificates are recreated if TTS_DOMAIN or any TTS_SUBJECT_* variable below changes.
Database is reset if TTS_DOMAIN, TTS_ADMIN_EMAIL, TTS_ADMIN_PASSWORD or TTS_CONSOLE_SECRET change.

Alternatively you can run the `reset.sh` script fro within the container and restart it.

```
docker exec -it stack /home/thethings/reset.sh
```

### Configuring the IP and domain

You want to assign your device a fixed IP or a domain name where you can always reach it. Here you have a few clues on how to do it.

#### Static IP

To reach the IP or to properly configure a domain or subdomain you will have to configure the Raspberry Pi with a static address. You have two options here:

1. Configure a static lease on your home router linking the RPi MAC with an IP. Everytime the RPi boots it will ask for an IP using DHCP (this is the default) and router will allways gfive it the same IP.

2. Configure a static IP on the RPi itself instead of using DHCP. 

#### Configuring the domain or subdomain

Once you know the PI will always be accessible at the same IP, there are a number of ways to define a domain name or a subdomain pointing to the device IP. After doing any of these approaches change the TTS_DOMAIN environment variable accordingly so the stack service recreates the right certificates for the domain.

1. Using a DNS in your LAN, like PiHole, dnsmask,... these will work great inside your LAN. But this option requires an extra step since BalenaOS by default uses Google DNS servers (8.8.8.8). So you have to instruct it to use your local DNS server instead. 

2. Using a third party service, like Cloudflare, for instance. If you are managing a domain from such a service you can just add an A register for a subdomain pointing to your local (or public) IP address.

```
A lns.ttn.cat 192.168.1.25
```

Then you just have to wait for the domain name to propagate.

### CLI Auto Login

The `ttn-lw-cli` is a CLI (Command Line Interface) tool that allows you to create or edit gateways and devices and can be very handly to automate tasks. The tool is included and available from within the container but first step to use it is to configure it (`ttn-lw-cli use <lns_ip>`) and login (`ttn-lw-cli login`). By setting the `CLI_AUTO_LOGIN` variable to `true` these initial steps will be done for you by first creating a API key for the admin user and then using it to pre-login the CLI tool. The default value for the `CLI_AUTO_LOGIN` variable is `false` which means that you will have to perform these step manually.

Either way, manually or automatically, you will be able to run the tool with the usual arguments by typing from the host `docker exec -it stack ttn-lw-cli`. For instance, to create a new gateway you will just have to:

```
docker exec -it stack ttn-lw-cli gateways create my-gateway-001 --user-id admin  --frequency-plan-id EU_863_870 --gateway-eui --gateway-eui 0011223344556677 --enforce-duty-cycle
```

### Packet Broker

The Packet Broker is a service provided by The Things Industries (TTI) that allows peering between networks. To use the Pacet Broker you need:

* A NetID provided by the LoRaWAN Alliance or a subrange of addresses from an existing NetID (TTI provides such service)
* A Packet Broker ID and Secret provided by TTI

If you want to fully integrate your cluster with The Things Network, this can be achieved by configuring TTS_NET_ID to "000013" (NetID owned by The Things Industries) and set the TTS_DEVADDR_RANGE to the range leased from TTI. Then configure the rest of PB_* variables with the info provided by TTI. All these variables must go to the `environment` section in the `stack` service or added as environment variables in the Balena Dashboard.

### Variables

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**TTS_SERVER_NAME** | `STRING` | Name of the server | The Things Stack
**TTS_DOMAIN** | `STRING` | Domain | Required, will not boot if undefined
**TTS_ADMIN_EMAIL** | `STRING` | Admin email | admin@thethings.example.com
**TTS_NOREPLY_EMAIL** | `STRING` | Email used for communications | noreply@thethings.example.com
**TTS_ADMIN_PASSWORD** | `STRING` | Admin password (change it here or in the admin profile) | changeme
**TTS_CONSOLE_SECRET** | `STRING` | Console secret | console
**TTS_DEVICE_CLAIMING_SECRET** | `STRING` | Device claiming secret | device_claiming
**TTS_METRICS_PASSWORD** | `STRING` | Metrics password | metrics
**TTS_PPROF_PASSWORD** | `STRING` | Profiling password | pprof
**TTS_SMTP_HOST** | `STRING` | SMTP Server |  
**TTS_SMTP_USER** | `STRING` | SMTP User |  
**TTS_SMTP_PASS** | `STRING` | SMTP Password |  
**TTS_SENDGRID_KEY** | `STRING` | Sendgrid API Key (SMTP_HOST has to be empty in order to use this) | 
**TTS_SUBJECT_COUNTRY** | `STRING` | Self Certificate country code| ES
**TTS_SUBJECT_STATE** | `STRING` | Self Certificate state | Catalunya
**TTS_SUBJECT_LOCATION** | `STRING` | Self Certificate city | Barcelona
**TTS_SUBJECT_ORGANIZATION** | `STRING` | Self Certificate organization | TTN Catalunya
**TTS_NET_ID** | `HEX` | Network ID | 000000
**TTS_DEVADDR_RANGE** | `HEX/INT` | Device address range | 00000000/7
**PB_HOME_ENABLE** | `true` or `false` | Network is home network from the Packet Broker point of view | `false`
**PB_FORWARDER_ENABLE** | `true` or `false` | Network is forwarder network from the Packet Broker point of view | `false`
**PB_HOST** | `STRING` | Packet Broker host address | eu.packetbroker.io:443
**PB_TENANT_ID** | `STRING` | Tenant ID | Empty if you own the NetID
**PB_OAUTH_ID** | `STRING` | Packet Broker API key ID | 
**PB_OAUTH_SECRET** | `STRING` | Packet Broker API secret | 
**CLI_AUTO_LOGIN** | `true` or `false` | Enable CLI automatic login (see CLI Auto Login section above) | `false`

**Note**: the container uses the `wait` tool (https://github.com/ufoscout/docker-compose-wait) to check that Redis and PostgreSQL are running before starting the stack. The **WAIT_\*** environment variables are there to configure this feature.

## Troubleshooting

### Certificates errors

If you are having certificates problems or "token rejected" message on the TTS website, try forcing a certificate regeneration:

```
docker exec stack ./reset_certs.sh
docker restart stack
```

If you reset the certs (by running `reset_certs.sh` or changing any of these variables: `TTS_SUBJECT_COUNTRY`, `TTS_SUBJECT_STATE`, `TTS_SUBJECT_LOCATION`, `TTS_SUBJECT_ORGANIZATION` or `TTS_DOMAIN`) you will need to fetch the new certificate to update any gateways connecting to the server using BasicStation:

```
docker exec stack ./get_certificate.sh
```

### Database reset

If you are having certificates problems or "token rejected" message on the TTS website, try forcing a certificate regeneration:

```
docker exec stack ./reset_db.sh
docker restart stack
```

When the database is reconfigured (because you ran `reset_db.sh` or changed any of these variables: `TTS_ADMIN_EMAIL`, `TTS_ADMIN_PASSWORD`, `TTS_CONSOLE_SECRET` or `TTS_DOMAIN`) the passwords for the admin and the console are overwritten. So if you are logged in as admin you will have to logout and login again with the default password.

### Using The Things Stack with BasicStation

When used together (same machine) with the [BasicStation](https://github.com/xoseperez/basicstation) packet forwarder the following matrix will help you identify working combinations.

|BasicStation<br />configuration|If TTS_DOMAIN is<br />an IP|If TTS_DOMAIN is<br />a domain name|
|---|:-:|:-:|
|Using localhost: LNS<sup>1</sup>|OK|OK|
|Using localhost: CUPS<sup>1</sup>|Works bypassing SNI check<sup>5</sup>|OK<sup>2</sup>|
|Using localhost: Web UI|OK|OK|
|Using IP: LNS|Works bypassing SNI check<sup>5</sup>|Works bypassing SNI check<sup>5</sup>|
|Using IP: CUPS|Works bypassing SNI check<sup>5</sup>|Works bypassing SNI check<sup>2,5</sup>|
|Using IP: Web UI|OK|OK<sup>3</sup>|
|Using domain name: LNS|Works bypassing SNI check<sup>5</sup>|OK|
|Using domain name: CUPS|Works bypassing SNI check<sup>5</sup>|OK|
|Using domain name: Web UI|OK<sup>4</sup>|OK|

1. Basicstation in the same machine as TTS and using network_mode host.
2. Works only if the domain name resolves OK from the basicstation container (CUPS response redirects to `wss://<domain_name>:8887`)
3. User gets redirected to `https://<domain_name>` after login, hence domain name must resolve to the IP.
4. User gets redirected to `https://<ip>` after login, hence domain name must resolve to the same IP.
5. Basicstation service allows to disable server name indication (SNI) check by setting TLS_SNI to `false`. See https://github.com/xoseperez/basicstation/issues/4#issuecomment-1230138180.

Therefore:

1. **Using a domain name for your machine is the best option. Set `TTS_DOMAIN` to that name. The name should resolve from the same machine and from the network that will be accessing the server. Use the same domain name everywhere.**
2. If you cannot have a domain name, you can use the IP of the machine as `TTS_DOMAIN` and bypass any possible certificate errors by setting `TLS_SNI` to `false` in your basicstation service. This is OK for private deployments with self-signed certificates.

## TODO

* Lots of testing :)
* Testing performance (# of devices) on different platforms
* Option to use ACME / Let's Encrypt for valid certificates
* Option to configure a connection to the Packet Broker

## Attribution

- This is based on the [The Things Network LoRaWAN Stack repository](https://github.com/TheThingsNetwork/lorawan-stack).
- This is in joint effort by [Xose Pérez](https://twitter.com/xoseperez/) and [Marc Pous](https://twitter.com/gy4nt/) from the TTN community in Barcelona.

triton-touchbase
==========

*[Touchbase](https://github.com/couchbaselabs/touchbase) stack designed for container-native deployment on Joyent's Triton platform*

This repo is a demonstation of a multi-tier container-native application architecture on [Joyent's](https://www.joyent.com/) Triton platform. It uses Touchbase and its supporting services as an example. It includes the following components:

- [Touchbase](https://www.joyent.com/blog/how-to-dockerize-a-complete-application#touchbase), a Node.js application
- [Nginx](https://www.joyent.com/blog/how-to-dockerize-a-complete-application#nginx), acting as a load balancer for Touchbase nodes
- [Couchbase](https://www.joyent.com/blog/how-to-dockerize-a-complete-application#couchbase), for the data tier
- Consul, acting as a discovery service
- Containerbuddy, to help with service discovery
- [CloudFlare-watcher](https://www.joyent.com/blog/how-to-dockerize-a-complete-application#cloudflare-watcher), to update DNS
- CloudFlare DNS, to make the site accessible by domain name on the Internet
- Triton, our container-native infrastructure platform

![Diagram of Touchbase architecture](./doc/triton-touchbase.png)

### Running the example

You can run this entire stack using the [`start.sh` script](https://github.com/tgross/triton-touchbase/blob/master/start.sh) found at the top of the repo. You'll need a CloudFlare account and a domain for which you've delegated DNS to CloudFlare, but if you'd like to skip that part you can simply comment out `startCloudflare` line.

Once you're ready:

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent CloudAPI CLI tools](https://apidocs.joyent.com/cloudapi/#getting-started) (including the `smartdc` and `json` tools)
1. Have your CloudFlare API key handy.
1. [Configure Docker and Docker Compose for use with Joyent](https://docs.joyent.com/public-cloud/api-access/docker):

```bash
curl -O https://raw.githubusercontent.com/joyent/sdc-docker/master/tools/sdc-docker-setup.sh && chmod +x sdc-docker-setup.sh
./sdc-docker-setup.sh -k us-east-1.api.joyent.com <ACCOUNT> ~/.ssh/<PRIVATE_KEY_FILE>
```


At this point you can run the example on Triton:

```bash
./start.sh env
# here you'll be asked to fill in the .env file
./start.sh

```

or in your local Docker environment (note that you may need to increase the memory available to your docker-machine VM to run the full-scale cluster):

```bash
./start.sh env
./start.sh -f docker-compose-local.yml

```

The `.env` file that's created will need to be filled in with the values described below:

```
CF_API_KEY=<your CloudFlare API key>
CF_AUTH_EMAIL=<the email address associated with your CloudFlare account>
CF_ROOT_DOMAIN=<the root domain you want to manage. ex. example.com>
SERVICE=nginx <the name of the service you want to monitor>
RECORD=<the A-record you want to manage. ex. my.example.com>
TTL=600 <the DNS TTL you want, in seconds. min 120, max 2147483647>
COUCHBASE_USER=<the administrative user you want for your Couchbase cluster>
COUCHBASE_PASS=<the password you want for that Couchbase user>

```

As the start script runs, it will launch the Consul web UI and the Couchbase web UI. Once Nginx is running, it will launch the login page for the Touchbase site. At this point there is only one Couchbase node, one application server and one Nginx server and you will see the message:

```
Touchbase cluster is launched!
Try scaling it up by running: ./start.sh scale
```

If you do so you'll be running `docker-compose scale` operations that add 2 more Couchbase and Touchbase nodes and 1 more Nginx node. You can watch as nodes become live by checking out the Consul and Couchbase web UIs.

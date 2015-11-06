triton-touchbase
==========

*[Touchbase](https://github.com/couchbaselabs/touchbase) stack designed for container-native deployment on Joyent's Triton platform*

This repo is a demonstation of a multi-tier container-native application architecture on [Joyent's](https://www.joyent.com/) Triton platform. It uses Touchbase and its supporting services as an example. It includes the following components:

- Consul, acting as a discovery service
- Couchbase, for the data tier
- Touchbase, a Node.js application
- Nginx, acting as a load balancer for Touchbase nodes
- CloudFlare-watcher, to update DNS
- CloudFlare DNS, to make the site accessible by domain name on the Internet

![Diagram of Touchbase architecture](./doc/triton-touchbase.png)

### Couchbase

Couchbase is a clustered NoSQL database. This uses [@misterbisson's](https://github.com/misterbisson/) blueprint for [clustered Couchbase in containers](https://github.com/misterbisson/clustered-couchbase-in-containers), using the [`triton-couchbase`](https://github.com/misterbisson/triton-couchbase) repo for Couchbase 4.0 to provide access to the new N1QL feature.

When the first Couchbase node starts, we use `docker exec` to bootstrap the cluster and register the first node with Consul for discovery. We'll then run the appropriate REST API calls to create Couchbase buckets and indexes for our application. At this point, we can add new nodes via `docker-compose scale` and those nodes will pick up a Couchbase cluster IP from Consul. At that point, we hand off to Couchbase's own self-clustering.

### Touchbase

The Touchbase Node.js application was written by Couchbase Labs as a demonstration of Couchbase 4.0's new N1QL query features. It wasn't especially designed for a container-native world, so this repo uses [Containerbuddy](https://github.com/joyent/containerbuddy/) to allow it to fulfill our requirements for service discovery.

Touchbase uses Couchbase as its data layer. This repo uses a [fork of Touchbase](https://github.com/tgross/touchbase) that eliminates the requirement to configure SendGrid, because setting up transactional email services is beyond the scope of this example.

The Touchbase service's Containerbuddy has an `onChange` handler that calls out to `consul-template` to write out a new `config.json` file based on a template that stored in Consul. Touchbase does not support a graceful reload, so in order to give Touchbase an initial configuration with a Couchbase cluster IP, so a pre-start script has been included to do so.

### Nginx

The Nginx virtualhost config has an `upstream` directive to run a round-robin load balancer for the backend Touchbase application nodes. When Touchbase nodes come online, they'll register themselves with Consul. The Nginx service's Containerbuddy has an `onChange` handler that calls out to `consul-template` to write out a new virtualhost configuration file based a template that we've stored in Consul. It then fires an `nginx -s reload` signal to Nginx, which causes it to [gracefully reload](http://nginx.org/en/docs/control.html#reconfiguration) its configuration.

### CloudFlare-watcher

The [`cloudflare` container](https://github.com/tgross/triton-cloudflare/) has a Containerbuddy `onChange` handler that updates CloudFlare via [their API](https://api.cloudflare.com/). The handler is a [bash script](https://github.com/tgross/triton-cloudflare/blob/master/update-dns.sh) that queries the CloudFlare API for existing A records, and then diffs these against the IP addresses known to Consul. If there's a change, it adds new records first and then removes any stale records.

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
TTL=600 <the DNS TTL you want>
CB_USER=<the administrative user you want for your Couchbase cluster>
CB_PASSWORD=<the password you want for that Couchbase user>

```

As the start script runs, it will launch the Consul web UI and the Couchbase web UI. Once Nginx is running, it will launch the login page for the Touchbase site. At this point there is only one Couchbase node, one application server and one Nginx server and you will see the message:

```
Touchbase cluster is launched!
Try scaling it up by running: ./start scale
```

If you do so you'll be running `docker-compose scale` operations that add 2 more Couchbase nodes and 1 more Touchbase and Nginx nodes. You can watch as nodes become live by checking out the Consul and Couchbase web UIs.

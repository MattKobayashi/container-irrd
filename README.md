# container-irrd

IRRd and IRR Explorer in a container image.

## Configuration

Create appropriate configuration files and mount them into the container as shown below. An example configuration file can be found [here](https://irrd.readthedocs.io/en/stable/admins/configuration/#example-configuration-file), and a list of all available configuration options can be found [here](https://irrd.readthedocs.io/en/stable/admins/configuration/#configuration-options).

### Required `irrd.yaml` values

- `irrd.database_url`: `"postgresql://irrd:irrd@irrd-database/irrd"`
- `irrd.redis_url`: `"redis://irrd-redis"`
- `irrd.piddir`: `/opt/irrd`
- `irrd.user`: `irrd`
- `irrd.group`: `irrd`

### Required `irrexplorer.yaml` values

- `irrexplorer.database_url`: `"postgresql://irrexplorer:irrexplorer@irrd-database/irrexplorer"`
- `irrexplorer.irrd_endpoint`: `"https://irrd.example.net/graphql/"`

## Running

Start the daemon:

```shell
docker run \
  -d \
  --name irrd \
  --volume /path/to/irrd.yaml:/etc/irrd.yaml \
  --volume /path/to/irrexplorer.yaml:/etc/irrexplorer.yaml \
  ghcr.io/mattkobayashi/irrd
```

## Explanatory notes

- Review the prerequisites for irrd [here](https://irrd.readthedocs.io/en/stable/admins/deployment/#requirements).

- Omit the `log.logfile_path` setting from your configuration file. This will log the daemon's output to `stdout`, allowing you to view logs with the `docker logs` command.

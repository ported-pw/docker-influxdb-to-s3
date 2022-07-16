# Docker InfluxDB to S3

This container periodically runs a backup of an InfluxDB database to an S3 bucket. It also has the ability to restore.

## Usage
For `INFLUX_TOKEN` you __must__ use the initial superuser token. You can find this using `influx auth list` on the InfluxDB server.


### Default cron (1am daily)

```shell
docker run \
    -e INFLUX_ORG=myorg
    -e INFLUX_BUCKET=mydatabase \
    -e INFLUX_HOST=http://1.2.3.4:8086 \
    -e INFLUX_TOKEN=sometoken
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    ported/influxdb-to-s3:latest
```

### Custom cron timing

```shell
docker run \
    -e INFLUX_ORG=myorg
    -e INFLUX_BUCKET=mydatabase \
    -e INFLUX_HOST=http://1.2.3.4:8086 \
    -e INFLUX_TOKEN=sometoken
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    ported/influxdb-to-s3:latest \
    cron "* * * * *"
```

### Run backup

```shell
docker run \
    -e INFLUX_ORG=myorg
    -e INFLUX_BUCKET=mydatabase \
    -e INFLUX_HOST=http://1.2.3.4:8086 \
    -e INFLUX_TOKEN=sometoken
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    ported/influxdb-to-s3:latest \
    backup
```

## Environment Variables

| Variable                | Description                                                    | Example Usage                   | Default                 | Optional?                    |
|-------------------------|----------------------------------------------------------------|---------------------------------|-------------------------|------------------------------|
| `INFLUX_HOST`           | URL of the influxdb instance                                   | `http://1.2.3.4:8086`           | None                    | No                           |
| `INFLUX_TOKEN`          | Auth token to use (see above)                                  | `somebase64==`                  | None                    | No                           |
| `INFLUX_ORG`            | Organisation the bucket is in                                  | `myorg`                         | None                    | Yes                          |
| `INFLUX_ORG_ID`         | Organisation ID the bucket is in (exclusive with `INFLUX_ORG`) | `b7b52d656895.....`             | None                    | Yes                          |
| `INFLUX_BUCKET`         | Bucket to backup                                               | `telegraf`                      | None                    | No                           |
| `S3_BUCKET`             | Name of bucket                                                 | `mybucketname`                  | None                    | No                           |
| `S3_KEY_PREFIX`         | S3 directory to place files in                                 | `backups` or `backups/sqlite`   | None                    | Yes                          |
| `S3_ENDPOINT_URL`       | Custom S3 endpoint URL                                         | `https://gateway.storjshare.io` | None                    | No                           |
| `AWS_ACCESS_KEY_ID`     | AWS Access key                                                 | `AKIAIO...`                     | None                    | Yes (if using instance role) |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key                                                 | `wJalrXUtnFE...`                | None                    | Yes (if using instance role) |
| `AWS_DEFAULT_REGION`    | AWS Default Region                                             | `us-west-2`                     | `us-west-1`             | Yes                          |
| `BACKUP_PATH`           | Directory to write the backup (within the container)           | `/myvolume/mybackup`            | `/data/influxdb/backup` | Yes                          |
| `BACKUP_ARCHIVE_PATH`   | Path to compress the backup (within the container)             | `/myvolume/mybackup.tgz`        | `${BACKUP_PATH}.tgz`    | Yes                          |

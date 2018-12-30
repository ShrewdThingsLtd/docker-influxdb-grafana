#!/bin/bash

IMG_TAG=${1:-local}
INFLUXDB_VERSION=${2:-1.7.2}
GRAFANA_VERSION=${3:-5.4.2}
NODE_VERSION=${4:-10}
INFLUXDB_INST=${5:-influxdb-box}

case ${IMG_TAG} in
	"hub")
	IMG_TAG=shrewdthingsltd/influxdb-box:$INFLUXDB_VERSION
	docker pull $IMG_TAG
	;;
	*)
	IMG_TAG=local/influxdb-box:$INFLUXDB_VERSION
	docker build \
		-t $IMG_TAG \
		--build-arg IMG_INFLUXDB_VERSION=$INFLUXDB_VERSION \
		--build-arg IMG_GRAFANA_VERSION=$GRAFANA_VERSION \
		--build-arg IMG_NODE_VERSION=$NODE_VERSION \
		./
	;;
esac

docker kill $INFLUXDB_INST
docker rm $INFLUXDB_INST
docker volume rm $(docker volume ls -qf dangling=true)
#docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }')
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
docker rm $(docker ps -qa --no-trunc --filter "status=exited")

docker run -d \
	--name $INFLUXDB_INST \
	-p 3003:3003 \
	-p 3004:8083 \
	-p 8086:8086 \
	-v $(pwd)/data/influxdb:/var/lib/influxdb \
	-v $(pwd)/data/grafana:/var/lib/grafana \
	$IMG_TAG

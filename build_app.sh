#!/usr/bin/env bash
set -o errexit
set -o nounset
# set -o xtrace
set -o pipefail

export DOCKER_USER="dkirkpatrick7"
export APP_PATH="./app"
export APP_NAME="exampleapp"
export APP_VERSION=`cat ./app/version.txt`

echo "Cleaning out any previous build for ${DOCKER_USER}/${APP_NAME}:${APP_VERSION}..."
docker rmi ${DOCKER_USER}/${APP_NAME}:${APP_VERSION} -f
echo "Building new image for ${DOCKER_USER}/${APP_NAME}:${APP_VERSION}..."
docker build -t ${DOCKER_USER}/${APP_NAME}:${APP_VERSION} .
docker image ls ${DOCKER_USER}/${APP_NAME}
echo "Pushing image to dockerhub..."
#docker commit -m "Added ${APP_NAME}:${APP_VERSION}" -a "Dennis D. Kirkpatrick" ${APP_NAME} ${DOCKER_USER}/${APP_NAME}:${APP_VERSION}
docker push ${DOCKER_USER}/${APP_NAME}

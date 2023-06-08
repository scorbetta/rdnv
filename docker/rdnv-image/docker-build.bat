@echo off

:: Name of the image to build
set image_name=rdnv-image
:: Dockerfile
set dockerfile=Dockerfile
:: Container name
set container_name=rdnv

:: Remove all containers that instantiate desired image
set _cmd="docker ps --filter ancestor=%image_name% -q"
for /f %%d in ('%_cmd%') do (
	echo "info: Removing container with ID=%%d"
	docker rm --force %%d
)

:: Remove all dangling images
set _cmd="docker images --filter dangling=true -q"
for /f %%d in ('%_cmd%') do (
	echo "info: Removing dangling image with ID=%%d"
	docker rmi --force %%d
)

:: Build image from scratch
docker build --no-cache -t %image_name% . -f %dockerfile%

:: Start container
docker run -dit --name %container_name% %image_name%

:: Open a TTY session in the container
docker exec -it %container_name% /bin/bash

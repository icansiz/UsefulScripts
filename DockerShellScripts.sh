// Docker container filtering and get ids
docker ps -a|grep Exited|awk '{print $1}'
// or
docker ps -a|grep Exited|cut -f 1 -d " "

// Remove all stopped containers
docker container prune


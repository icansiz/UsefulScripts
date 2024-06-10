// Docker container filtering and get ids
docker ps -a|grep Exited|awk '{print $1}'
// or
docker ps -a|grep Exited|cut -f 1 -d " "

// Remove all stopped containers
docker container prune

// restart all containers
docker restart $(docker ps -a -q)

// copy file from host to conainer
docker cp /usr/oracle/oracle-sample-database.zip 0ba992c506fd:/home/oracle


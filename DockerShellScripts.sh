// Docker container filtering and get ids
docker ps -a|grep Exited|awk '{print $1}'

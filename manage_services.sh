#!/usr/bin/env bash

# Import util functions
if [ -f ./util.sh ]; then
  source ./util.sh
else
  echo "Failed to find util.sh"
  exit 1
fi

# Directories containing Kubernetes YAML manifests
declare -A serviceConfigPaths
serviceConfigPaths=(
  ["gateway"]="src/gateway/manifests"
  ["auth"]="src/auth/manifests"
  ["rabbit"]="src/rabbit/manifests"
  ["converter"]="src/converter/manifests"
)
services=("gateway" "auth" "rabbit" "converter")

list_all_services() {
    for service in "${services[@]}"; do
        echo "Service Name: $service"
        echo "Config Path: ${serviceConfigPaths[$service]}"
        echo "----------"
    done
}

start_services() {
  check_docker
  check_kubectl
  check_minikube
  if [ $? -ne 0 ]; then
    run_minikube
  fi
  for service in "${services[@]}"; do
    echo "Applying configuration for $service"
    echo "----------"
    kubectl apply -f "${serviceConfigPaths[$service]}"
    # if starting gateway service, tunnel must also be set
    #if [ $service = "gateway" ]; then
      #run_tunnel
    #fi

  done
}

stop_services() {
  for service in "${services[@]}"; do
    echo "Deleting configuration for $service"
    echo "----------"
    # if starting gateway service, tunnel must be closed
    #if [ $service = "gateway" ]; then
      #stop_tunnel
    #fi
    kubectl delete -f "${serviceConfigPaths[$service]}"
  done
}

start_specific_service() {
  check_docker
  check_kubectl
  check_minikube
  local SERVICE_NAME=$1
  local CONFIG_PATH="${serviceConfigPaths[$SERVICE_NAME]}"

  if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Configuration path for service '$SERVICE_NAME' not found."
    return 1
  fi

  echo "Starting service $SERVICE_NAME, config path:${serviceConfigPaths[$SERVICE_NAME]}..."
  kubectl apply -f "$CONFIG_PATH"
}

stop_specific_service() {
  local SERVICE_NAME=$1
  local CONFIG_PATH="${serviceConfigPaths[$SERVICE_NAME]}"

  if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Configuration path for service '$SERVICE_NAME' not found."
    return 1
  fi

  echo "Stopping service $SERVICE_NAME, config path:${serviceConfigPaths[$SERVICE_NAME]}..."
  kubectl delete -f "$CONFIG_PATH"
}

restart_specific_service() {
  local service_name=$1
  echo "Restarting service: $service_name"

  stop_specific_service "$service_name"
  sleep 1
  start_specific_service "$service_name"
}

rebuild_service() {
  local SERVICE_NAME=$1
  local CONFIG_PATH="${serviceConfigPaths[$SERVICE_NAME]}"
  local DOCKER_NAME="$SERVICE_NAME"
  local DOCKERFILE_PATH=$(dirname "$CONFIG_PATH")

  if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Configuration path for service '$SERVICE_NAME' not found."
    return 1
  fi

  if [ "$SERVICE_NAME" = "rabbit" ]; then
    DOCKER_NAME="rabbitmq"
  fi

  echo "Building docker image"
  docker build -t aminfarjadi/$DOCKER_NAME:latest $DOCKERFILE_PATH || { echo "Failed to build image from $DOCKERFILE_PATH"; return 1; }
  echo "----------"
  echo "Pushing image"
  docker push aminfarjadi/$DOCKER_NAME:latest || { echo "Failed to push image $DOCKER_NAME:latest"; return 1; }
  sleep 1
  echo "----------"
  echo "Stopping service $SERVICE_NAME"
  stop_specific_service $SERVICE_NAME || { echo "Failed to stop $SERVICE_NAME"; return 1; }
  echo "----------"
  echo "Applying new configuration for $SERVICE_NAME"
  kubectl apply -f $CONFIG_PATH || { echo "Faield to apply configuration for $SERVICE_NAME"; return 1; }
}

scale_up_service() {
  local SERVICE_NAME=$1
  local CONFIG_PATH="${serviceConfigPaths[$SERVICE_NAME]}"
  local SERVICE_TYPE="deployment"

  if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Configuration path for service '$SERVICE_NAME' not found."
    return 1
  fi

  if [ "$SERVICE_NAME" = "rabbit" ]; then
    SERVICE_TYPE="statefulset"
  fi

  descired_replicas=$(kubectl get $SERVICE_TYPE $SERVICE_NAME -o jsonpath='{.spec.replicas}')
  if [ $? -ne 0 ]; then
    echo "Error fetching replicas for $SERVICE_NAME"
    exit 1
  fi

  echo "Scaling $SERVICE_NAME to $descired_replicas replicas"
  kubectl scale $SERVICE_TYPE $SERVICE_NAME --replicas=$descired_replicas
  echo "----------"
}

scale_down_service() {
  local SERVICE_NAME=$1
  local CONFIG_PATH="${serviceConfigPaths[$SERVICE_NAME]}"
  local SERVICE_TYPE="deployment"

  if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Configuration path for service '$SERVICE_NAME' not found."
    return 1
  fi

  if [ "$SERVICE_NAME" = "rabbit" ]; then
    SERVICE_TYPE="statefulset"
  fi

  echo "Scaling $SERVICE_NAME to 0 replicas"
  kubectl scale $SERVICE_TYPE $SERVICE_NAME --replicas=0
  echo "----------"
}

if [ "$#" = "0" ]; then
  echo "Usage: $0 <start|stop|start-service|stop-service|restart-service|rebuild|scale-up|scale-down|list> [service-name]"
  exit 1
fi

case "$1" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  start-service)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 stop-service <service-name>"
      exit 1
    fi
    start_specific_service "$2"
    ;;
  stop-service)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 stop-service <service-name>"
      exit 1
    fi
    stop_specific_service "$2"
    ;;
  restart-service)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 restart-service <service-name>"
      exit 1
    fi
    restart_specific_service "$2"
    ;;
  rebuild)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 rebuild <service-name>"
      exit 1
    fi
    rebuild_service "$2"
    ;;
  scale-up)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 scale-up <service-name>"
      exit 1
    fi
    scale_up_service "$2"
    ;;
  scale-down)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 scale-down <service-name>"
      exit 1
    fi
    scale_down_service "$2"
    ;;
  list)
    list_all_services
    ;;
  *)
    echo "Invalid command: $1"
    echo "Usage: $0 <start|stop|start-service|stop-service|restart-service|rebuild|scale-up|scale-down|list> [service-name]"
    exit 1
    ;;
esac


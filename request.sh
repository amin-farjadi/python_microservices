#!/usr/bin/env bash

if [ -f ./util.sh ]; then
  source ./util.sh
else
  echo "Failed to find util.sh"
  exit 1
fi

check_minikube() {
  status=$(minikube status --format '{{.Host}}'; echo)
  if [[ $status != "Running" ]]; then
    echo "Minikube is not running. Please run \`minikube start\`."
    exit 1
  else
    return 0
  fi
}

check_tunnel() {
  if ps aux | grep -q "[m]inikube tunnel"; then
    return 0
  else
    echo "Minikube tunnel is not running. Please run \`minikube tunnel\`"
    exit 1
  fi
}

get_jwt() {
  local USERNAME='farjadi_amin@yahoo.com'
  local PASSWORD='Admin123'
  local ENDPOINT='http://mp3converter.com/login'
  local ENDPOINT_ERROR="invalid credentials"
  check_minikube
  if [ $? -ne 0 ]; then
    run_minikube
  fi
  check_tunnel
  if [ $? -ne 0 ]; then
    run_tunnel
  fi
  tmp_file=$(mktemp)
  status_code=$(curl -s -w "%{http_code}" -o $tmp_file -X POST -u $USERNAME:$PASSWORD $ENDPOINT)
  body=$(cat $tmp_file)
  rm $tmp_file

  if [[ "$status_code" != "200" ]]; then
    echo $body
    return 1
  fi

  echo $body
  return 0
}

upload_video() {
  local VIDEO_PATH='./video_example.mp4'
  local ENDPOINT='http://mp3converter.com/upload'
  jwt=$(get_jwt)
  if [ $? -ne 0 ]; then
    echo "Error in getting jwt: $jwt"
    exit 1
  fi
  tmp_file=$(mktemp)
  status_code=$(curl -s -w "%{http_code}" -o $tmp_file -X POST -F "file=@$VIDEO_PATH" -H "Authorization: Bearer $jwt" $ENDPOINT)
  response=$(cat $tmp_file)
  rm $tmp_file

  if [[ "$status_code" != "200" ]]; then
    echo "Error in uploading file"
    echo "-----------------------"
    echo "Status code: $status_code"
    echo "Response body: $response"
    exit 1
  fi

  echo "File successfully uploaded: $response"
}

if [ "$#" = "0" ]; then
  echo "Usage: $0 "
  exit 1
fi

case "$1" in
  upload)
    upload_video
    ;;
  *)
    echo "Invalid command: $1"
    echo "Usage: $0 "
    exit 1
    ;;
esac


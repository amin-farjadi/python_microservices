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

download_mp3() {
  local mp3_fid=$1
   count_file=".download_count.txt"
  # Check if the count file exists and create it if it doesn't
  if [ ! -f "${count_file}" ]; then
    echo 0 > "${count_file}"
  fi
  
  # Read the current count from the file
  count=$(cat "${count_file}")
  count=$((count + 1))
  
  # Save the updated count back to the file
  echo "${count}" > "${count_file}"

  mp3_filename="mp3_download_${count}.mp3"
  jwt=$(get_jwt)
  BASEURL='http://mp3converter.com/download?fid='

  status_code=$(curl --silent --output $mp3_filename --write-out "%{http_code}" -X GET -H "Authorization: Bearer $jwt" "$BASEURL$mp3_fid")

  if [[ "$status_code" != "200" ]]; then
    echo "Download failed. Status code: $status_code"
    return 1
  fi

  echo "mp3 file downloaded to $mp3_filename"
  return 0
}



if [ "$#" = "0" ]; then
  echo "Usage: $0 "
  exit 1
fi

case "$1" in
  upload)
    upload_video
    ;;
  download)
    if [ "$#" -ne 2 ]; then
      echo "Usage: $0 download <mp3 file id (fid)>"
      exit 1
    fi
    download_mp3 $2
    ;;
  *)
    echo "Invalid command: $1"
    echo "Usage: $0 "
    exit 1
    ;;
esac


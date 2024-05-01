check_docker() {
  # Check if the Docker daemon is active
  if ! command -v docker &> /dev/null; then
    echo "Docker command could not be found. Please install Docker."
    exit 1
  fi

    # Use the 'docker info' command which only succeeds if Docker daemon is running
    docker info &> /dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      echo "Docker is not running. Please start Docker."
      exit 1
    fi
}

check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo "kubectl command could not be found. Please install kubectl."
    exit 1
  fi
  return 0
}

check_minikube() {
  if ! command -v minikube &> /dev/null; then
    echo "Minikube command could not be found. Please install Minikube."
    exit 1
  fi
  status=$(minikube status --format '{{.Host}}'; echo)
  if [[ $status != "Running" ]]; then
    echo "Minikube is not running. Running Minikube."
    return 1
  fi
  return 0
}

run_minikube() {
  minikube start
}

check_tunnel() {
  if ps aux | grep -q "[m]inikube tunnel"; then
    return 0
  else
    echo "Minikube tunnel is not running. Please run \`sudo minikube tunnel\`"
    return 1
  fi
}

#run_tunnel() {
  #check_tunnel
  #if [ $? -eq 0 ]; then
    #echo "Tunnel already running."
    #return 0
  #fi
  ## AppleScript to open a new iTerm window and run a command
  #echo "Starting tunnel in a new iTerm window"
  #osascript <<EOF
  #tell application "iTerm"
    #activate
    #try
      #set newWindow to (create window with default profile)
    #on error
      #set newWindow to current window
    #end try
    #tell newWindow
      #launch session "Default Session"
      #tell the current session
        #write text "minikube tunnel"
      #end tell
    #end tell
  #end tell
#EOF
#}

#stop_tunnel() {
  #check_tunnel
  #if [ $? -ne 0 ]; then
    #echo "No tunnel is running"
    #return 0
  #fi
  ## AppleScript wrapped in a bash script to find and close the iTerm window running 'minikube tunnel'
  #osascript <<EOF
  #tell application "iTerm"
    #set found to false
    #repeat with aWindow in windows
      #repeat with aTab in tabs of aWindow
        #repeat with aSession in sessions of aTab
          #if name of aSession contains "minikube tunnel" then
            #set found to true
            #tell aSession
              #write text "^C"
            #end tell
            #delay 2
            #close aTab
            #break
          #end if
        #end repeat
        #if found then break
      #end repeat
      #if found then break
    #end repeat
  #end tell
#EOF
#}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  if [ "$#" -ne 1 ]; then
    echo "Usage: $0"
    exit 1
  fi

  case "$1" in
    check-minikube)
      check_minikube
      ;;
    #start-tunnel)
      #run_tunnel
      #;;
    #stop-tunnel)
      #stop_tunnel
      #;;
    *)
      echo "Invalid command: $1"
      echo "Usage: $0"
      exit 1
      ;;
  esac
fi

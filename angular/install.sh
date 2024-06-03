function main {
  bash server.sh &
  wait $!
  bash client.sh
}

main
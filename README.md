# Video Converter

This project is inspired by the tutorial found [here](https://www.youtube.com/watch?v=hmkF77F9TLw).
A video converter platform is implemented where user uploads video to the site,
the video gets converted to an audio file and the user receives an email notification containing
the link to the audio file.

This project uses the following tools in its stack:
- Docker
- Kubernetes
- MongoDB
- MySQL/MariaDB
- Python (Flask)

The platform is broken down into the following microservices:
- Gateway
- Authentication
- Converter
- Notification<br>
and are coupled using a RabbitMQ message-broker.


The secret file for the notification service is ommitted as it contains sensitive information
about the email service used to send notification emails.
Other secret files contain unimportant secrets that were used for local deployment.

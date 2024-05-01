import smtplib, os, json
from email.message import EmailMessage

def notification(message):

    try:
        message = json.loads(message)
        mp3_fid = message["mp3_fid"]
        sender_address = os.environ.get("GMAIL_ADDRESS")
        sender_password = os.environ.get("GMAIL_PASSWORD")
        receiver_address = message["username"]
        if not sender_address:
            return Exception("Sender email address not found.")
        if not sender_password:
            return Exception("Sender email password not found.")
        if not receiver_address:
            return Exception("Receiver email address not provided.")

        msg = EmailMessage()
        msg.set_content(f"mp3 file_id: {mp3_fid} is now ready!")
        msg["Subject"] = "MP3 Download"
        msg["From"] = sender_address
        msg["To"] = receiver_address

        session = smtplib.SMTP("smtp.gmail.com", 587)
        session.starttls()
        session.login(sender_address,sender_password)
        session.send_message(msg,sender_address,receiver_address)
        session.quit()

        print("Email sent.")

    except Exception as err:
        print(f"{err}")
        return err

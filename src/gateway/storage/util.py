import pika, json
from pika.spec import PERSISTENT_DELIVERY_MODE





def upload(f, fs, channel, access):

    try:
        fid = fs.put(f)

    except Exception:
        return "internal server error", 500

    message = {
        "video_fid": str(fid),
        "mp3_id": None,
        "username": access["username"],
    }

    try:
        channel.basic_publish(
            exchange="",
            routing_key="video",
            body=json.dumps(message),
            properties=pika.BasicProperties(
            delivery_mode=PERSISTENT_DELIVERY_MODE
            ),
        )

    except Exception:
        fs.delete(fid)
        return "internal server error", 500




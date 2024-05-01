from gridfs import GridFS, errors
import pika, json
from pika.spec import PERSISTENT_DELIVERY_MODE





def upload(f, fs, channel, access):

    try:
        fid = fs.put(f)

    except errors.FileExists:
        return "File has already been uploaded", 409

    except Exception:
        return "Error in saving the video: gateway.storage.util.upload", 500

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
        return "Error in publishing video to the queue: gateway.storage.util.upload", 500




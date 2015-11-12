import re
import random
from apiclient.discovery import build
from apiclient.errors import HttpError


def youtube_search(q):
    # TODO: insert developer key
    youtube = build("youtube", "v3", developerKey="")

    # call the search.list method

    search_response = youtube.search().list(
        q=q,
        part="id,snippet",
        maxResults=5,
        videoDuration="short",
        type="video",
        safeSearch="moderate"
    ).execute()

    ret = []
    for search_result in search_response.get("items", []):
        # only fetch videos
        if search_result["id"]["kind"] != "youtube#video":
            continue

        # append to videos
        ret.append((search_result["snippet"]["title"], search_result["id"]["videoId"]))

    return ret

# parameters
label_file = "resources/labels.txt"

# videos to download
to_download = 500

# load labels
with open(label_file) as f:
    # regular exploression from removing ID from the beginning
    strip_id = re.compile(r"^n\d+ ")

    # extract all labels (remove ID from beginning, trip new line character and split words)
    labels = [x for l in f.readlines() for x in strip_id.sub("", l).strip().split(", ")]

    # run until download is full
    download_list = []
    while len(download_list) < to_download:
        # make query
        query_terms = random.choice(labels)
        if 0.5 < random.random():  # use two labels half the time
            query_terms += " " + random.choice(labels)

        # run query
        try:
            videos = youtube_search(query_terms)
        except HttpError, e:
            print "An HTTP error %d occurred:\n%s" % (e.resp.status, e.content)
            break

        # select two files to download
        for (title, video_id) in videos[0:2]:
            # print "Download: %s" % title
            download_list.append("http://youtube.com/watch?v=%s" % video_id)

    # print download list
    for download in download_list:
        print download

# to download, use something like `youtube-dl`
import time
import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/", methods=['GET'])
def index(host_ip=os.environ['MY_HOST_IP']):
  page_html = "<h1>Node IP: %s</h1>" % host_ip
  page_html += "<h2>Caller's IP: %s</h2>" % request.environ.get('HTTP_X_REAL_IP', request.access_route[-1])
  page_html += "<h2>Timestamp: %s</h2>" % time.asctime(time.gmtime())
  return page_html

if __name__ == "__main__":
  app.run(debug=True, host='0.0.0.0')
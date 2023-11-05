function generate_new_project {
  ng new client
  install_client_dependencies
  cd client/src || exit
  reset_css
  client_utils
  cd ../ || exit
  tailwind_setup
}

function install_client_dependencies {
  npm install --save @types/node
  npm install --save @types/uuid
  npm install rxjs
  npm install -D tailwindcss postcss autoprefixer
  npm install tailwind-scrollbar-hide
  npm install @fortawesome/angular-fontawesome
  npm install --save @fortawesome/fontawesome-svg-core
  npm install --save @fortawesome/free-brands-svg-icons
#    npm install --save @fortawesome/pro-solid-svg-icons
#    npm install --save @fortawesome/pro-regular-svg-icons
#    npm install --save @fortawesome/pro-light-svg-icons
#    npm install --save @fortawesome/pro-thin-svg-icons
#    npm install --save @fortawesome/pro-duotone-svg-icons
#    npm install --save @fortawesome/sharp-solid-svg-icons
#    npm install --save @fortawesome/sharp-regular-svg-icons
#    npm install --save @fortawesome/sharp-light-svg-icons
#    npm install --save @fortawesome/fontawesome-pro
}

function reset_css {
  touch reset.css
  echo "html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed,
figure, figcaption, footer, header, hgroup,
menu, nav, output, ruby, section, summary,
time, mark, audio, video {
	margin: 0;
	padding: 0;
	border: 0;
	font-size: 100%;
	font: inherit;
	vertical-align: baseline;
}
/* HTML5 display-role reset for older browsers */
article, aside, details, figcaption, figure,
footer, header, hgroup, menu, nav, section {
	display: block;
}
body {
	line-height: 1;
}
ol, ul {
	list-style: none;
}
blockquote, q {
	quotes: none;
}
blockquote:before, blockquote:after,
q:before, q:after {
	content: '';
	content: none;
}
table {
	border-collapse: collapse;
	border-spacing: 0;
}" >>reset.css
}

function client_utils {
  mkdir utils
  cd utils || exit
  touch icons.ts
  cd ../ || exit
}

function tailwind_setup {
  touch tailwind.config.cjs
  echo "
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./**/*.html'],
  theme: {
    extend: {
      fontSize: {
        '1': '1px',
      }
    },
  },
  plugins: [
    require('tailwindcss'),
    require('autoprefixer'),
    require('tailwind-scrollbar-hide')
  ],
}" >>tailwind.config.cjs

  cd src || exit
  echo "@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';
  " >>styles.scss

  cd ../ || exit
}

function create_server {
  mkdir server
  cd server || exit
  install_server_dependencies
  create_utils
  create_template
  create_database
  create_resource
  create_process
  create_env_variables
  create_limiter
  cd ../
}

function install_server_dependencies {
  touch requirements.txt
  echo "fastapi~=0.103.1
starlette~=0.27.0
python-dotenv~=1.0.0
pymongo~=4.5.0
uvicorn~=0.22.0
  " >>requirements.txt
  python3.9 -m venv venv
  source venv/bin/activate
  pip3 install -r requirements.txt
}

function create_utils {
  touch utils.py
  echo "class Status:

  OK = 200
  CREATED = 201
  ACCEPTED = 202
  NO_CONTENT = 204

  BAD_REQUEST = 400
  UNAUTHORIZED = 401
  FORBIDDEN = 403
  NOT_FOUND = 404

  INTERNAL_SERVER_ERROR = 500
  " >>utils.py
}

function create_template {
  touch template.py
  echo "
  class Template:

    @staticmethod
    def generate(status: int, results: list = None, message: str = None) -> dict:
        """"""
        return {
            'status': status,
            'results': results,
            'message': message
        }
  " >>template.py
}

function create_database {
  touch database.py
  echo "import pymongo
from pymongo.results import UpdateResult, DeleteResult, InsertOneResult
from bson import ObjectId

class Database:

    def __init__(self, url: str, db_name: str):
        self.client = pymongo.MongoClient(url)
        self.database = self.client[db_name]
        self._collection = None

    def __enter__(self) -> 'Database':
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.client.close()

    @property
    def collection(self) -> pymongo.collection.Collection:
        return self._collection

    @collection.setter
    def collection(self, value: str) -> None:
        self._collection = self.database[value]

    async def insert_document(self, data: dict) -> InsertOneResult:
        return self.collection.insert_one(data)

    async def find_documents(self, query=None) -> list:
        if query is None:
            query = {}
        results = list(self.collection.find(query))
        return await Database.convert_ids(results)

    @staticmethod
    async def convert_ids(results: list) -> list:
        for item in results:
            if not isinstance(item['_id'], ObjectId):
                continue
            item['_id'] = str(item['_id'])
        return results

    async def update_document(self, query: dict, data: dict, delete: bool = False) -> UpdateResult:
        return self.collection.update_one(
            query, {'$unset': data} if delete else {'$set': data}
        )

    async def delete_document(self, query: dict) -> DeleteResult:
        return self.collection.delete_one(query)

    async def delete_many(self) -> DeleteResult:
        return self.collection.delete_many({})

    async def count_documents(self, query=None) -> int:
        if query is None:
            query = {}
        return self.collection.count_documents(query)
  " >>database.py
}

function create_resource {
  touch resource.py
  echo "from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import FileResponse
from dotenv import load_dotenv

from process import Process
from starlette.requests import Request
from limiter import RateLimiter


load_dotenv()
app = FastAPI()
ALL = ['*']
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=ALL,
    allow_methods=ALL,
    allow_headers=ALL,
)


# app.get('/', dependencies=[Depends(default_limiter)])
strict_limiter = RateLimiter(max_requests=2, time_window=60)
default_limiter = RateLimiter(max_requests=5, time_window=60)
tolerant_limiter = RateLimiter(max_requests=20, time_window=60)


# GET http://localhost:8000/
@app.get('/')
async def root():
    return {'message': 'FBH'}
  " >>resource.py
}

function create_process {
  touch process.py
  echo "import os
from dotenv import load_dotenv
from database import Database
from utils import Status
from template import Template

class Process:

  load_dotenv()
  _MONGO_URI: str = os.getenv('MONGO_URI')
  _DB_NAME: str = os.getenv('DB_NAME')
  _INSTANCE: 'Process' = None
  _DB = Database(_MONGO_URI, _DB_NAME)

  def __new__(cls, *args, **kwargs) -> 'Process':
      if not cls._INSTANCE:
          cls._instance = super(Process, cls).__new__(cls, *args, **kwargs)
      return cls._INSTANCE

  @staticmethod
  async def results(collection: str) -> dict:
      Process._DB.collection = collection
      results = await Process._DB.find_documents()
      if not results:
          return Template.generate(status=Status.INTERNAL_SERVER_ERROR)
      return Template.generate(status=Status.OK, results=results)
  " >>process.py
}

function create_env_variables {
  touch .env
  echo "MONGO_URI=''
DB_NAME=''
  " >>.env
}

function create_limiter {
  touch limiter.py
  echo "from collections import defaultdict, deque
from fastapi import HTTPException, Request
import time


class RateLimiter:

    def __init__(self, max_requests: int, time_window: int):
        self.max_requests = max_requests
        self.time_window = time_window
        self.clients = defaultdict(deque)

    def __call__(self, request: Request):
        client_address = request.client.host
        current_time = time.time()

        if client_address not in self.clients:
            self.clients[client_address] = deque()

        client_times = self.clients[client_address]
        while client_times and client_times[0] < current_time - self.time_window:
            client_times.popleft()

        if len(client_times) < self.max_requests:
            client_times.append(current_time)
            return
        else:
            raise HTTPException(status_code=429, detail='Too many requests.')
  " >>limiter.py
}

function main {
  create_server &
  sleep 10
  generate_new_project
}

main
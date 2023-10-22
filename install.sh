#!/bin/zsh

# Server functions
function create_resource {
  echo "
import functools
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import Response
from starlette.requests import Request
from dotenv import load_dotenv
from process import Process
from project import Project

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


def cache(seconds: int) -> callable:
  def decorator(func: callable) -> callable:
      @functools.wraps(func)
      def wrapper(*args, **kwargs) -> callable:
          response = args[0]
          response.headers['Cache-Control'] = 'public, max-age={}'.format(seconds)
          return func(*args, **kwargs)
      return wrapper
  return decorator


# GET http://localhost:8000/
@cache(Project.CACHE_TIME)
@app.get('/')
async def root():
    return {'message': 'FBH'}
  " >>resource.py
}

function create_process {
  echo "
import os
from dotenv import load_dotenv
from database import Database
from utils import Status
from template import Template

class Process:

  load_dotenv()
  _MONGO_URI: str = os.getenv('MONGO_UR')
  _DB_NAME: str = os.getenv('DB_NAME')
  _INSTANCE: 'Process' = None
  _db = Database(_MONGO_URI, _DB_NAME)

  def __new__(cls, *args, **kwargs) -> 'Process':
      if not cls._INSTANCE:
          cls._instance = super(Process, cls).__new__(cls, *args, **kwargs)
      return cls._INSTANCE
  ">>process.py
}

function create_utils {
  echo "
class Status:

  OK = 200
  CREATED = 201
  ACCEPTED = 202
  NO_CONTENT = 204

  BAD_REQUEST = 400
  UNAUTHORIZED = 401
  FORBIDDEN = 403
  NOT_FOUND = 404

  INTERNAL_SERVER_ERROR = 500
  ">>utils.py
}

function create_response_template {
  echo "
class Template:

    """"""
    @staticmethod
    def generate(status_code: int, results: list = None, message: str = None) -> dict:
        """"""
        return {
            'status_code': status_code,
            'results': results,
            'message': message
        }
  ">>template.py
}

function create_database {
  echo "
import pymongo
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

function env_variables {
  echo "
MONGO_URI=''
DB_NAME=''
  " >>.env
}

function create_project {
  echo "
class Project:
  NAME: str = ''
  VERSION: str = ''
  CACHE_TIME: int = (60**2*7*24)
  ">>project.py
}

function create_server {
  mkdir server || exit
  cd server || exit
  touch resource.py process.py project.py utils.py database.py .env requirements.txt
  python3 -m venv venv || exit
  source venv/bin/activate
  pip3 install fastapi
  pip3 install uvicorn
  pip3 install python-dotenv
  pip3 install icecream
  pip3 install pymongo
  pip3 install starlette

  env_variables
  create_resource
  create_process
  create_utils
  create_response_template
  create_database
  create_project
  cd ../ || exit
}

# Client functions
function setup_vite {
  yarn create vite client --template react-ts
  cd client || exit
  touch yarn.lock
  yarn
}

function install_client_dependencies {
  yarn add react-query
  yarn add react-router-dom
  yarn add framer-motion
  yarn add tailwind-scrollbar-hide
  yarn add @fortawesome/fontawesome-svg-core \
    @fortawesome/free-solid-svg-icons \
    @fortawesome/free-brands-svg-icons \
    @fortawesome/free-regular-svg-icons \
    @fortawesome/react-fontawesome
}

function setup_tailwindcss {
  yarn add -D tailwindcss postcss autoprefixer
  touch tailwind.config.cjs
  touch postcss.config.cjs
  echo "module.exports = {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  }" >>postcss.config.cjs
  echo "/** @type {import('tailwindcss').Config} */
  module.exports = {
      content: [
          './src/**/*.html',
          './src/**/*.jsx',
          './src/**/*.js',
          './src/**/*.ts',
          './src/**/*.tsx'
      ],
      theme: {
          extend: {
              fontFamily: {
                  'sans': ['Oxygen', 'sans-serif'],
                  'mono': ['Oxygen Mono', 'monospace']
              }
          },
          screens: {
              'sm': '640px',
              'md': '768px',
              'lg': '1024px',
              'xl': '1280px'
          }
      },
      plugins: [],
  }" >>tailwind.config.cjs
}

function structure_client_project {
  rm -rf src || exit
  mkdir src || exit
  cd src || exit
  mkdir types utils hooks constants components styles assets
}

function create_base_types {
  cd types || exit
  touch Base.ts
  echo "
  export interface BaseComponent {
    mobile?: boolean;
    className?: string;
    isModal?: boolean;
    setIsModal?: (value: boolean) => void;
  }" >>Base.ts
  cd ../ || exit
}

function create_base_hooks {
  cd hooks || exit
  touch useKeyboard.ts useMobile.ts
  echo "
  import {useEffect, useState} from 'react';

  export default function useWindowSize(): boolean {

    const [mobile, setMobile] = useState<boolean>(window.innerWidth < 1024);

    useEffect(() => {
        function resize(): void {
            setMobile(window.innerWidth < 1024);
        }

        window.addEventListener('resize', resize);
        return () => window.removeEventListener('resize', resize);
    })

    return mobile;
  }
  " >>useMobile.ts
  echo "
  import {useEffect} from 'react';

  export default function useKeyboard(key: string, action: () => void) {
      useEffect(() => {
          const handler = (e: KeyboardEvent) => {
              if (e.key === key) action();
          }
          window.addEventListener('keydown', handler);
          return () => window.removeEventListener('keydown', handler);
      })
  }
  " >>useKeyboard.ts
  cd ../ || exit
}

function create_client_utils {
  cd utils || exit
  touch Icons.tsx Keyboard.ts Requests.ts Animate.ts
  echo "
  const enum ENDPOINTS {}
  const enum QUERY_KEYS {}

  const HEADERS = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };

  export async function GET(endpoint: string): Promise<any> {
    const response = await fetch(endpoint);
    return await response.json();
  }

  export async function POST(endpoint: string, data: any): Promise<any> {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(data),
    });
    return await response.json();
  }

  export async function PUT(endpoint: string, data: any): Promise<any> {
    const response = await fetch(endpoint, {
      method: 'PUT',
      headers: HEADERS,
      body: JSON.stringify(data),
    });
    return await response.json();
  }

  export async function DELETE(endpoint: string): Promise<any> {
    const response = await fetch(endpoint, {
      method: 'DELETE',
      headers: HEADERS,
    });
    return await response.json();
  }
  " >>requests.ts
  cd ../ || exit
}

function create_client_styles {
  echo "
  /* https://tailwindcss.com/docs/customizing-colors */
  @import url('https://fonts.googleapis.com/css2?family=Oxygen:wght@300;400;700&display=swap');
  @import url('https://fonts.googleapis.com/css2?family=Oxygen+Mono&display=swap');
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  body {
      background: #09090b;
  }

  " >>index.css
}

function create_client_entry {
  touch index.css main.tsx App.tsx
  echo "
  import React from 'react';
  import ReactDOM from 'react-dom/client';
  import './index.css';
  import App from './App';
  import { QueryClient, QueryClientProvider } from 'react-query';

  const queryClient = new QueryClient();

  ReactDOM.createRoot(document.getElementById('root') as HTMLDivElement).render(
    <React.StrictMode>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </React.StrictMode>
  );" >>main.tsx
  echo "
  export default function App(): JSX.Element {
    return (
        <div className={'App'}>
            {'FBH'}
        </div>
    );
  }" >>App.tsx
}

# Execution of client creation functions
function create_client {
  setup_vite
  install_client_dependencies
  setup_tailwindcss
  structure_client_project
  create_base_types
  create_base_hooks
  create_client_utils
  create_client_styles
  create_client_entry
}

create_server &
wait %1
create_client

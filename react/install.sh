#!/bin/zsh

# Server functions
function create_resource {
  echo "import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import Response
from starlette.requests import Request
from dotenv import load_dotenv
from process import Process

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


# GET http://localhost:8000/
@app.get('/')
async def root() -> None:
    return {}
  " >>resource.py
}

function create_process {
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

  INTERNAL_SERVER_ERROR = 500" >>utils.py
}

function create_response_template {
  echo "
class Template:

    """"""
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
            query, {'\$unset': data} if delete else {'\$set': data}
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

function create_server {
  mkdir server || exit
  cd server || exit
  touch resource.py process.py project.py utils.py database.py models.py sandbox.py .env requirements.txt
  echo "fastapi~=0.103.1
starlette~=0.27.0
python-dotenv~=1.0.0
pymongo~=4.5.0
uvicorn~=0.22.0
icecream~=2.1.3">>requirements.txt
  python3.8 -m venv .venv || exit
  source .venv/bin/activate
  pip3 install -r requirements.txt

  env_variables
  create_resource
  create_process
  create_utils
  create_response_template
  create_database
  cd ../ || exit
}

function setup_vite {
  yarn create vite client --template react-ts
  cd client || exit
  touch yarn.lock
  yarn
}

function install_client_dependencies {
  npm i uuid
  npm install --save @types/node
  yarn add react-query
  yarn add react-router-dom
  yarn add framer-motion
  yarn add tailwind-scrollbar-hide
  yarn add @fortawesome/fontawesome-svg-core \
    @fortawesome/free-solid-svg-icons \
    @fortawesome/free-brands-svg-icons \
    @fortawesome/free-regular-svg-icons \
    @fortawesome/react-fontawesome

  yarn add @fortawesome/free-brands-svg-icons
  yarn add @fortawesome/pro-solid-svg-icons
  yarn add @fortawesome/pro-regular-svg-icons
  yarn add @fortawesome/pro-light-svg-icons
  yarn add @fortawesome/pro-thin-svg-icons
  yarn add @fortawesome/pro-duotone-svg-icons
  yarn add @fortawesome/sharp-solid-svg-icons
  yarn add @fortawesome/sharp-regular-svg-icons
  yarn add @fortawesome/sharp-light-svg-icons

  npm install --save @fortawesome/fontawesome-pro
  yarn add @fortawesome/fontawesome-pro
}

function setup_tailwindcss {
  cd ../ || exit
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

function create_rc {
touch .yarnrc.yml

  echo "
plugins:
  dotenv: { }
npmScopes:
  fortawesome:
    npmAlwaysAuth: true
    npmRegistryServer: 'https://npm.fontawesome.com/'
    npmAuthToken: ""
  " >>.yarnrc.yml
}

function create_environment {
  touch environment.ts
  echo "
export const environment = {
  isProduction: false
};">>environment.ts
}

function structure_client_project {
  rm -rf src || exit
  create_rc

  mkdir src || exit
  cd src || exit
  mkdir types utils hooks constants components styles assets context
  create_environment
  create_context
  create_components
}

function create_components {
  cd components || exit
  mkdir ui
  cd ui || exit
  mkdir modal notification nav
  cd modal || exit
  touch modal.component.tsx modal.model.tsx
  echo "
const enum Common {
 PARENT = ''
}

export const enum Mobile {
 PARENT = \`\${Common.PARENT}\`
}

export const enum Desktop {
 PARENT = \`\${Common.PARENT}\`
}">.modal.model.tsx
  cd ../notification || exit
  touch notification.component.tsx notification.model.tsx
  echo "
const enum Common {
 PARENT = ''
}

export const enum Mobile {
 PARENT = \`\${Common.PARENT}\`
}

export const enum Desktop {
 PARENT = \`\${Common.PARENT}\`
}">.notification.model.tsx
  cd ../nav || exit
  touch nav.component.tsx nav.model.tsx
  echo "
const enum Common {
 PARENT = ''
}

export const enum Mobile {
 PARENT = \`\${Common.PARENT}\`
}

export const enum Desktop {
 PARENT = \`\${Common.PARENT}\`
}">.nav.model.tsx
  cd ../../../ || exit
}

function create_base_types {
  cd types || exit
  touch base.model.tsx
  echo "
  export interface BaseModel {
    mobile?: boolean;
    className?: string;
  }" >>base.model.tsx
  cd ../ || exit
}

function create_mobile_hook {
  touch useMobile.ts
  echo "
import {useEffect, useState} from 'react';

export default function useMobile(): boolean {

  const [mobile, setMobile] = useState<boolean>(window.innerWidth < 1024);

  useEffect(() => {
      function resize(): void {
          setMobile(window.innerWidth < 1024);
      }

      window.addEventListener('resize', resize);
      return () => window.removeEventListener('resize', resize);
  })

  return mobile;
}" >>useMobile.ts
}

function create_notification_hook {
  touch useNotification.ts
  echo "
import {useState, useEffect} from 'react';
import {NotificationModel} from '../components/ui/notification/Notification.model.tsx';
import {IconDefinition} from '@fortawesome/pro-light-svg-icons';

export const useNotification = (delay: number = 3000) => {
  const [notification, setNotification] = useState<NotificationModel | undefined>();

  const showNotification = (message: string, icon?: IconDefinition) => {
    setNotification({message, icon});
    const timeout = setTimeout(() => {
      setNotification(undefined);
    }, delay);
    return () => clearTimeout(timeout);
  };

  useEffect(() => {
    return () => {
      if (notification) {
        setNotification(undefined);
      }
    };
  }, [notification]);

  return {notification, showNotification};
};" >>useNotification.ts
}

function create_keyboard_hook {
  touch useKeyboard.ts
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
}

function create_base_hooks {
  cd hooks || exit
  create_mobile_hook
  create_notification_hook
  create_keyboard_hook
  cd ../ || exit
}

function create_context {
  cd context || exit
  touch modal.context.tsx notification.context.tsx mobile.context.tsx
  cd ../ || exit
}

function create_keyboard_utils {
  touch keyboard.constants.tsx
  echo "
export const enum KEYBOARD {
  ENTER = 'Enter',
  ESCAPE = 'Escape',
  TAB = 'Tab',
  BACKSPACE = 'Backspace',
  SHIFT = 'Shift',
  CONTROL = 'Control',
  ALT = 'Alt',
  SPACE = 'Space',
  ARROWUP = 'ArrowUp',
  ARROWDOWN = 'ArrowDown',
  ARROWLEFT = 'ArrowLeft',
  ARROWRIGHT = 'ArrowRight',
  PAGEUP = 'PageUp',
  PAGEDOWN = 'PageDown',
  HOME = 'Home',
  END = 'End',
  INSERT = 'Insert',
  DELETE = 'Delete',
  NUMLOCK = 'NumLock',
  CAPSLOCK = 'CapsLock',
  SCROLLLOCK = 'ScrollLock',
  PAUSEBREAK = 'PauseBreak',
  F1 = 'F1',
  F2 = 'F2',
  F3 = 'F3',
  F4 = 'F4',
  F5 = 'F5',
  F6 = 'F6',
  F7 = 'F7',
  F8 = 'F8',
  F9 = 'F9',
  F10 = 'F10',
  F11 = 'F11',
  F12 = 'F12',
  META = 'Meta',
  CONTEXTMENU = 'ContextMenu',
  PRINTSCREEN = 'PrintScreen',
  A = 'KeyA',
  B = 'KeyB',
  C = 'KeyC',
  D = 'KeyD',
  E = 'KeyE',
  F = 'KeyF',
  G = 'KeyG',
  H = 'KeyH',
  I = 'KeyI',
  J = 'KeyJ',
  K = 'KeyK',
  L = 'KeyL',
  M = 'KeyM',
  N = 'KeyN',
  O = 'KeyO',
  P = 'KeyP',
  Q = 'KeyQ',
  R = 'KeyR',
  S = 'KeyS',
  T = 'KeyT',
  U = 'KeyU',
  V = 'KeyV',
  W = 'KeyW',
  X = 'KeyX',
  Y = 'KeyY',
  Z = 'KeyZ',
  DIGIT0 = 'Digit0',
  DIGIT1 = 'Digit1',
  DIGIT2 = 'Digit2',
  DIGIT3 = 'Digit3',
  DIGIT4 = 'Digit4',
  DIGIT5 = 'Digit5',
  DIGIT6 = 'Digit6',
  DIGIT7 = 'Digit7',
  DIGIT8 = 'Digit8',
  DIGIT9 = 'Digit9'
}" >>keyboard.constants.ts
}


function create_icon_constants {
  touch icons.constants.tsx
  echo "
  import {faGlobeEurope} from '@fortawesome/pro-light-svg-icons/faGlobeEurope';
import {faTrophy} from '@fortawesome/pro-light-svg-icons/faTrophy';
import {
  faBars, faBroomWide,
  faCat,
  faCheck, faDatabase, faExternalLink, faGear, faHouseLaptop, faLock,
  faMagicWandSparkles, faMagnifyingGlass,
  faPaperPlane,
  faPen,
  faPlus, faShare, faTableColumns,
  faTrashCan, faUnlock, faXmark, IconDefinition
} from '@fortawesome/pro-light-svg-icons';
import {faChevronLeft} from '@fortawesome/pro-light-svg-icons/faChevronLeft';
import {faChevronRight} from '@fortawesome/pro-light-svg-icons/faChevronRight';
import {faPaw} from '@fortawesome/pro-light-svg-icons/faPaw';
import {faInfoCircle} from '@fortawesome/pro-light-svg-icons/faInfoCircle';
import {faCode} from '@fortawesome/pro-light-svg-icons/faCode';

import {faGithub} from '@fortawesome/free-brands-svg-icons/faGithub';
import {faLinkedinIn} from '@fortawesome/free-brands-svg-icons/faLinkedinIn';
import {faJs, faPython, faReact} from '@fortawesome/free-brands-svg-icons';
import React from 'react';
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';

export const Brands = {
  GITHUB: faGithub,
  LINKED_IN: faLinkedinIn,
  REACT: faReact,
  TYPESCRIPT: faJs,
  PYTHON: faPython,
  MONGO: faDatabase,
} as Record<string, IconDefinition>;

export const Icons = {
  EARTH: faGlobeEurope,
  TROPHY: faTrophy,
  SUBMIT: faPaperPlane,
  CAT: faCat,
  ARROW_LEFT: faChevronLeft,
  ARROW_RIGHT: faChevronRight,
  PAW: faPaw,
  INFO: faInfoCircle,
  SPARKLES: faMagicWandSparkles,
  CODE: faCode,
  ADD: faPlus,
  TRASH: faTrashCan,
  PEN: faPen,
  CHECK: faCheck,
  CLOSE: faXmark,
  SEARCH: faMagnifyingGlass,
  EXTERNAL: faExternalLink,
  BARS: faBars,
  DASHBOARD: faTableColumns,
  SHARE: faShare,
  LOCK: faLock,
  UNLOCK: faUnlock,
  REMOTE: faHouseLaptop,
  BROOM: faBroomWide,
  SETTINGS: faGear
} as Record<string, IconDefinition>" >>icons.constants.tsx
}

function create_http_requests {
  touch requests.tsx
  echo "const host = '';

export const ENDPOINTS = {}
export const enum QUERY_KEYS {}

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
}" >>requests.tsx
}

function create_cache_methods {
  touch cache.tsx
  echo "
  export class Cache {

  private static readonly loot = {};

  static get keys() {
    return this.loot;
  }

  static getItem(key: string): any {
    if (!key) {
      return null;
    }
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  }

  static setItem(key: string, value: unknown): void {
    if (!key && !value) {
      return;
    }
    localStorage.setItem(key, JSON.stringify(value));
  }

  static removeItem(key: string): void {
    if (!key) {
      return;
    }
    localStorage.removeItem(key)
  }

  static clearCache(): void {
    localStorage.clear();
  }
}" >>cache.tsx
}

function create_animation_constants {
  touch animate.constants.tsx
  echo "
export const Initial = {
  OPACITY: {opacity: 0}
}

export const Animate = {
  OPACITY: {opacity: 1}
}

export const Exit = {
  OPACITY: {opacity: 0}
}

export const Transition = {
  DEFAULT: {duration: 0.5, ease: 'easeInOut'},
  LONGER: {duration: 1, ease: 'easeInOut'},
}

export const Hover = {
  BRIGHTNESS: {filter: 'brightness(1.1)'}
}

export const Tap = {
  PUSH: {scale: 0.95}
}" >>animate.constants.tsx
}

function create_project_routes {
  touch project.routes.tsx
  echo "
export const enum Routes {
  HOME = '/'
}" >>project.routes.tsx
}

function create_client_utils {
  cd utils || exit
  create_keyboard_utils
  create_icon_constants
  create_http_requests
  create_cache_methods
  create_animation_constants
  create_project_routes
  cd ../ || exit
}


function create_client_entry {
  create_client_styles
  create_main_component
  create_app_component
}

function create_client_styles {
  touch index.css
  echo "
/* https://tailwindcss.com/docs/customizing-colors */
@import url('https://fonts.googleapis.com/css2?family=Oxygen:wght@300;400;700&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Oxygen+Mono&display=swap');
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  background: #09090b;
}" >>index.css
}

function create_main_component {
  touch main.tsx
  echo "
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { QueryClient, QueryClientProvider } from 'react-query';
import {HashRouter as Router} from 'react-router-dom';
const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById('root') as HTMLDivElement).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <Router>
        <App />
      </Router>
    </QueryClientProvider>
  </React.StrictMode>
);" >>main.tsx
}

function create_app_component {
  touch app.component.tsx app.model.tsx
  echo "
import {BaseModel} from './types/base.model.tsx';
import {Mobile, Desktop} from './app.model.tsx/
import useWindowSize from './hooks/useMobile.ts';

export const App = function () {

  const mobile = useMobile();

  return (
      <div className={mobile ? Mobile.PARENT : Desktop.PARENT}>
      </div>
  );
}" >>app.component.tsx

  echo "
const enum Common {
 PARENT = ''
}

export const enum Mobile {
 PARENT = \`\${Common.PARENT}\`
}

export const enum Desktop {
 PARENT = \`\${Common.PARENT}\`
}">.app.model.tsx
}

# Execution of client creation functions
function create_client {
  setup_vite
  structure_client_project
  install_client_dependencies
  create_base_types
  create_base_hooks
  create_client_utils
  create_client_styles
  create_client_entry
  setup_tailwindcss
}

create_server &
wait %1
create_client

#!/bin/zsh

# create server directory with necessary files
function create_server {
  mkdir server || exit
  cd server || exit
  touch resource.py process.py project.py utils.py database.py .env
  python3 -m venv venv || exit
  source venv/bin/activate
  pip3 install fastapi
  pip3 install uvicorn
  pip3 install python-dotenv
  pip3 install icecream
  echo "
import functools
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import Response
from starlette.requests import Request
from dotenv import load_dotenv

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
@cache(60**2*24*7)
@app.get('/')
async def root():
    return {'message': 'FBH'}
" >>resource.py

echo "
import sqlite3
from typing import Optional, List


class Database:

  def __init__(self, db_name: str) -> None:
      if not db_name.endswith('.db'):
          raise ValueError('{} must end with .db'.format(db_name))
      self.name = db_name
      self.conn = self.connect()
      self.cur = self.cursor()

  def __enter__(self) -> 'Database':
      return self

  def __exit__(self, exc_type, exc_val, exc_tb) -> None:
      self.conn.close()

  def connect(self) -> sqlite3.Connection:
      if not self.name:
          raise ValueError('Database name not found')
      return sqlite3.connect(self.name)

  def cursor(self) -> sqlite3.Cursor:
      if not self.conn:
          raise ValueError('Connection not found')
      return self.conn.cursor()

  def commit(self) -> None:
      if not self.conn:
          raise ValueError('Connection not found')
      self.conn.commit()

  def execute(self, sql: str, data: dict = None) -> Optional[List[tuple]]:
      if not self.cur:
          raise ValueError('Cursor not found')
      if data:
          self.cur.execute(sql, data)
      else:
          self.cur.execute(sql)
      self.commit()
      return self.cur.fetchall()
  " >> database.py
  cd ../ || exit
}

# create client directory with necessary files
function create_client {
  yarn create vite client --template react-ts
  cd client || exit
  touch yarn.lock
  yarn
  yarn add react-query
  yarn add react-router-dom
  yarn add framer-motion
  yarn add @fortawesome/fontawesome-svg-core \
  @fortawesome/free-solid-svg-icons \
  @fortawesome/free-brands-svg-icons \
  @fortawesome/free-regular-svg-icons \
  @fortawesome/react-fontawesome
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
  rm -rf src || exit
  mkdir src || exit
  cd src || exit
  mkdir types utils hooks constants components styles
  touch index.css main.tsx App.tsx
  cd components || exit
  mkdir nav ui c1 c2 c3
  cd ../ || exit
  cd types || exit
  touch Base.ts
  echo "
  export interface BaseComponent {
    mobile?: boolean;
    className?: string;
    isModal?: boolean;
    setIsModal?: (value: boolean) => void;
  }" >> Base.ts
  cd ../ || exit
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
  cd ../utils || exit
  touch Icons.tsx Keyboard.ts Requests.ts
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

create_server &
wait %1
create_client

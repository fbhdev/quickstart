#!/bin/zsh

# create server directory with necessary files
function create_server {
  mkdir server || exit
  cd server || exit
  touch api.py database.py .env
  python3 -m venv venv || exit
  source venv/bin/activate
  pip3 install fastapi
  pip3 install uvicorn
  pip3 install python-dotenv
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
  app.add_middleware(
      CORSMiddleware,
      allow_origins=['*'],
      allow_credentials=True,
      allow_methods=['*'],
      allow_headers=['*'],
  )

  class Project:
      NAME: str = ''
      VERSION: str = ''


  def cache(minutes: int) -> callable:
    def decorator(func: callable) -> callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> callable:
            response = args[0]
            response.headers['Cache-Control'] = 'public, max-age={}'.format(minutes)
            return func(*args, **kwargs)
        return wrapper
    return decorator


  # GET http://localhost:8000/
  @cache(60)
  @app.get('/')
  async def root():
      return {'message': 'FBH'}
  " >>api.py

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
                  'sans': ['Oxygen', 'sans-serif']
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
  touch index.css main.tsx App.tsx
  echo "
  @import url('https://fonts.googleapis.com/css2?family=Oxygen:wght@300;400;700&display=swap');
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  body {
      background: #333333;
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
  async function GET(endpoint: string): Promise<any> {
    const response = await fetch(endpoint);
    return await response.json();
  }

  export default function App(): JSX.Element {
    return (
        <div className={"App"}>
            FBH
        </div>
    );
  }" >>App.tsx
}

create_server &
wait %1
create_client

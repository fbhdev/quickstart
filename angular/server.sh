#!/bin/bash

mkdir -p server && cd server || exit

# Create package.json
cat <<EOL > package.json
{
  "name": "express API",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "ts-node src/index.ts"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "mongodb": "^6.5.0",
    "ts-node": "^10.9.2"
  },
  "devDependencies": {
    "@types/cors": "^2.8.17",
    "@types/dotenv": "^8.2.0",
    "@types/express": "^4.17.21",
    "@types/node": "^20.12.6",
    "typescript": "^5.4.4"
  }
}
EOL

# Create tsconfig.json
cat <<EOL > tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "esModuleInterop": true,
    "target": "es6",
    "moduleResolution": "node",
    "removeComments": true,
    "sourceMap": false,
    "outDir": "./dist",
    "rootDir": "./src",
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "allowJs": true,
    "strict": false
  },
  "include": [
    "src"
  ],
  "exclude": [
    "node_modules",
    "dist/*",
    "src/static"
  ],
  "lib": [
    "es6"
  ]
}
EOL

mkdir -p src/controllers/root src/routes/root
cd src || exit

# Install dependencies
npm install

# Create index.ts
cat <<EOL > index.ts
import bodyParser from 'body-parser';
import express, {Express} from 'express';
import rootRouter from './routes/root/root';
import {MongoClient} from 'mongodb';
import cors from 'cors';
import dotenv from 'dotenv';

const PORT: number = 3000;

const onSuccess = function (): void {
    console.log(\`http://localhost:\${PORT}\`);
    console.log(\`Server is running on port \${PORT}\`);
}

async function start(): Promise<void> {
  try {
    const app: Express = express();
    dotenv.config();
    app.use(cors());

    const mongo: MongoClient = new MongoClient(process.env.MONGO_URI);
    await mongo.connect();
    app.set('db', mongo.db('portfolio'));

    app.use(bodyParser.json({
      limit: '500kb',
    }));

    // routes
    app.use('/', rootRouter);

    app.listen(PORT, onSuccess);

  } catch (error) {
    console.log(error);
  }
}

start();
EOL

# Create routes/root/root.ts
cat <<EOL > routes/root/root.ts
import {Router} from "express";
import { getRootController } from "../../controllers/root/getRoot";

const rootRouter: Router = Router();

rootRouter.get("/", getRootController);

export default rootRouter;
EOL

# Create controllers/root/getRoot.ts
cat <<EOL > controllers/root/getRoot.ts
import {Request, Response, NextFunction} from "express";

export async function getRootController(req: Request, res: Response, nextFn: NextFunction): Promise<void> {
    try {
        res.status(200).send("API works");
    } catch (error) {
        console.log(error);
    }
}
EOL

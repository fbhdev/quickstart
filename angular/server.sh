mkdir server && cd server || exit

touch package.json .env
echo '
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
    "types": "^0.1.1",
    "typescript": "^5.4.4"
  }
}' >> package.json


touch tsconfig.json
echo '
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
}' >> tsconfig.json

mkdir src
cd src || exit

npm install

# index
touch index.ts
echo "

import bodyParser from 'body-parser';
import express, {Express} from 'express';
import rootRouter from './routes/root';
import entriesRouter from './routes/entries';
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

    const mongo: MongoClient = await MongoClient.connect(process.ENV.MONGO_URI);
    await mongo.connect();
    app.set('db', mongo.db('portfolio'));

    app.use(bodyParser.json({ // Use bodyParser as middleware
      limit: '500kb',
    }));

    // routes

    app.listen(PORT, onSuccess);

  } catch (error) {
    console.log(error);
  }
}

start();
">>index.ts

mkdir controllers routes

# routes
cd routes || exit
mdkir root && cd root || exit
touch root.ts
echo 'import {Router} from "express";
import { getRootController } from "../controllers/root/getRoot";

const rootRouter: Router = Router();

rootRouter.get("/", getRootController);

export default rootRouter;' >>root.ts
cd ../../ || exit

# controllers
cd controllers || exit
mdkir root && cd root
touch getRoot.ts
echo 'import {Request, Response, NextFunction} from "express";

export async function getRootController(req: Request, res: Response, nextFn: NextFunction): Promise<void> {
    try {
        res.status(200).send("API works");
    } catch (error) {
        console.log(error);
    }
}'>>getRoot.ts
cd ../../../ || exit
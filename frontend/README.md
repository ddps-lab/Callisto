# Callisto Frontend

## `.env`
- You need to create a .env file and enter the required values before building (or running).
- example `.env` file
  ```text
  VITE_COGNITO_REGION="COGNITO REGION"
  VITE_COGNITO_USER_POOL_ID="COGNITO POOL ID"
  VITE_COGNITO_CLIENT_ID="COGNITO CLIENT_ID (Web-Frontend)"
  VITE_DB_API_URL="API GATEWAY - REST API URL"
  ``` 
## How to Run
- If yarn is not installed, run the following command first.
  ```shell
  npm install -g yarn
  ```
- When running in the dev environment, execute the following command.
  ```shell
  yarn
  yarn dev
  ```
## How to Build
- When building for deployment, execute the following command.
  ```
  yarn
  yarn build
  ```

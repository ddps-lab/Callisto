import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  QueryCommand,
  PutCommand,
  GetCommand,
  DeleteCommand,
} from "@aws-sdk/lib-dynamodb";
import { randomUUID } from 'crypto';

const region = process.env.AWS_REGION;
const client = new DynamoDBClient({ region });
const dynamo = DynamoDBDocumentClient.from(client);
const TableName = "callisto-jupyter";
const REQUIRED_FIELDS = ["name", "cpu_core", "memory"];

export const handler = async (event) => {
  let body, command, statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };

  try {
    const data = JSON.parse(event.body || "{}");
    switch (event.routeKey) {
      case "POST /jupyter":
        if (!REQUIRED_FIELDS.every((field) => data.hasOwnProperty(field) && data[field] != null)) {
          statusCode = 400;
          body = { message: "Missing required fields" };
          break;
        }
        statusCode = 201;
        command = {
          TableName,
          Item: {
            uid: data.uuid,
            user: data.user,
            name: data.name,
            cpu_core: data.cpu_core,
            memory: data.memory,
            storage: data.storage,
            endpoint: data.endpoint,
            inactivity_time: data.inactivity_time,
            cost: 0,
            created_at: new Date().getTime(),
          }
        };
        await dynamo.send(new PutCommand(command));
        body = { message: "Inference created", inference: command };
        break;

        case "GET /jupyter":
        body = await dynamo.send(new QueryCommand({
          TableName,
          IndexName: "user-index",
          KeyConditionExpression: "#user = :user",
          ExpressionAttributeNames: {
            "#user": "user"
          },
          ExpressionAttributeValues: {
            ":user": event.headers.user,
          },
        }));
        body = body.Items;
        break;

      case "GET /jupyter/{id}":
        body = await dynamo.send(new GetCommand({
          TableName,
          Key: {
            uid: event.pathParameters.id,
          },
        }));
        body = body.Item;
        break;

      case "PUT /jupyter/{id}":
        const { Item } = await dynamo.send(new GetCommand({
          TableName,
          Key: {
            uid: event.pathParameters.id,
          },
        }));  
        if (!Item) {
          statusCode = 404;
          body = { message: "Not Found" };
          break;
        }
        command = {
          TableName,
          Item: {
            ...Item,
            name: data.name || Item.name,
            cpu_core: data.cpu_core || Item.cpu_core,
            storage: data.storage || Item.storage,
            memory: data.memory || Item.memory,
            endpoint: data.endpoint || Item.endpoint,
            inactivity_time: data.inactivity_time || Item.inactivity_time,
            cost: data.cost || Item.cost,
            updated_at: new Date().getTime(),
          }
        };
        await dynamo.send(new PutCommand(command));
        body = { message: "Inference updated", inference: command.Item };
        break;

      case "DELETE /jupyter/{id}":
        await dynamo.send(new DeleteCommand({
          TableName,
          Key: {
            uid: event.pathParameters.id,
          },
        }));
        body = { message: "Jupyter deleted", uid: event.pathParameters.id };
        break;
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return { statusCode, body, headers };

};

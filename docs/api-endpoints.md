# Hexaphexah API Documentation
Version: 1.0.0
Last Updated: 2024-12-28

## Base URL
```
Development: http://localhost:3000/api
Production: https://api.hexaphexah.com/api
```

## Authentication
All endpoints require JWT authentication header:
```
Authorization: Bearer <token>
```

## Endpoints

### Materials Management

#### Get Material List
```http
GET /materials
```

Query Parameters:
```json
{
  "type": "string",
  "manufacturer": "string",
  "page": "number",
  "limit": "number"
}
```

Response:
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "type": "AEROGEL|POLYIMIDE|TITANIUM|D3O",
      "properties": {},
      "manufacturer": {},
      "created_at": "datetime",
      "updated_at": "datetime"
    }
  ],
  "pagination": {
    "total": "number",
    "page": "number",
    "limit": "number"
  }
}
```

#### Create Material
```http
POST /materials
```

Request Body:
```json
{
  "name": "string",
  "type": "AEROGEL|POLYIMIDE|TITANIUM|D3O",
  "manufacturer_id": "string",
  "properties": {
    "thermal_conductivity": "number",
    "max_temperature": "number",
    "density": "number"
  }
}
```

### Manufacturing Process

#### Get Manufacturing Batch
```http
GET /manufacturing/batch/{batch_id}
```

Response:
```json
{
  "id": "string",
  "status": "string",
  "start_time": "datetime",
  "end_time": "datetime",
  "parameters": {},
  "quality_checks": [],
  "yield": "number"
}
```

#### Create Manufacturing Batch
```http
POST /manufacturing/batch
```

Request Body:
```json
{
  "materials": [
    {
      "material_id": "string",
      "quantity": "number"
    }
  ],
  "parameters": {
    "temperature": "number",
    "pressure": "number",
    "duration": "number"
  }
}
```

### Quality Control

#### Submit Test Results
```http
POST /quality/test
```

Request Body:
```json
{
  "batch_id": "string",
  "test_type": "string",
  "results": {
    "value": "number",
    "unit": "string",
    "pass": "boolean"
  },
  "notes": "string"
}
```

#### Get Quality Report
```http
GET /quality/report/{batch_id}
```

Response:
```json
{
  "batch_id": "string",
  "tests": [
    {
      "type": "string",
      "results": {},
      "timestamp": "datetime",
      "status": "string"
    }
  ],
  "overall_status": "string"
}
```

### Composite Configuration

#### Get Composite Specification
```http
GET /composite/{id}
```

Response:
```json
{
  "id": "string",
  "name": "string",
  "layers": [
    {
      "material_id": "string",
      "thickness": "number",
      "order": "number",
      "properties": {}
    }
  ],
  "total_thickness": "number",
  "thermal_rating": "number"
}
```

#### Create Composite Configuration
```http
POST /composite
```

Request Body:
```json
{
  "name": "string",
  "layers": [
    {
      "material_id": "string",
      "thickness": "number",
      "order": "number"
    }
  ],
  "specifications": {
    "thermal_requirement": "number",
    "flexibility": "number",
    "impact_resistance": "number"
  }
}
```

### Equipment Management

#### Get Equipment Status
```http
GET /equipment/{id}
```

Response:
```json
{
  "id": "string",
  "name": "string",
  "status": "string",
  "last_maintenance": "datetime",
  "next_maintenance": "datetime",
  "calibration_status": "string"
}
```

#### Log Equipment Maintenance
```http
POST /equipment/{id}/maintenance
```

Request Body:
```json
{
  "type": "string",
  "description": "string",
  "technician": "string",
  "parts_replaced": [
    {
      "part_id": "string",
      "quantity": "number"
    }
  ]
}
```

## Error Responses

Standard error response format:
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": {}
  }
}
```

Common Error Codes:
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 409: Conflict
- 422: Unprocessable Entity
- 500: Internal Server Error

## Rate Limiting

- Rate limit: 1000 requests per minute
- Rate limit header: X-RateLimit-Limit
- Remaining requests header: X-RateLimit-Remaining
- Reset time header: X-RateLimit-Reset

## Webhook Events

Subscribe to events:
```http
POST /webhooks
```

Request Body:
```json
{
  "url": "string",
  "events": [
    "material.created",
    "batch.completed",
    "quality.failed",
    "maintenance.required"
  ]
}
```

## Development Tools

### API Client Example
```typescript
import { HexaphexahClient } from '@hexaphexah/client';

const client = new HexaphexahClient({
  apiKey: 'your-api-key',
  baseUrl: 'https://api.hexaphexah.com/api'
});

// Get material list
const materials = await client.materials.list({
  type: 'AEROGEL',
  limit: 10
});

// Create manufacturing batch
const batch = await client.manufacturing.createBatch({
  materials: [
    { material_id: 'material-id', quantity: 1.5 }
  ],
  parameters: {
    temperature: 350,
    pressure: 1.5,
    duration: 120
  }
});
```

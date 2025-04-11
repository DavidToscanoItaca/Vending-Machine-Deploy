# Beverage Vending Machine System

## Project Overview

This project aims to develop a system to manage a beverage vending machine. Each beverage has a recipe consisting of a list of ingredients. The system allows users to select a beverage, insert coins, specify the desired sugar level, and receive their beverage if sufficient ingredients are available.

## Features

1. **Beverage Selection**: Users can choose from a variety of beverages.
2. **Coin Insertion**: Users insert coins to pay for the selected beverage.
3. **Sugar Level Specification**: Users can specify the desired sugar level (from 1 to 5).
4. **Ingredient Check**: The system checks if there are enough ingredients to prepare the beverage.
5. **Beverage Dispensing**: If sufficient ingredients are available, the beverage is dispensed and change is returned.
6. **Transaction Propagation**: Successful transactions are propagated as a JSON object into BSV (Bitcoin SV).

## Technologies Used

- **Node.js**: For building RESTful APIs.
<!-- - **TAAL API**: For broadcasting transactions to BSV. You can create a free account and obtain an API key [here](https://platform.taal.com/pricing?plan=taal-api). -->

## Installation

1. Clone the repository

2. Navigate to the project directory:
    ```bash
    cd beverage-vending-machine
    ```
3. Install dependencies:
    ```bash
    npm install
    ```

4. Build:
    ```bash
    npm run build
    ```

## Running the Service

<!-- 1. Create a `.env` file in the root directory and add the following environment variables:
    ```plaintext
    BROADCASTER_URL=your_broadcaster_url
    BROADCASTER_APIKEY=your_broadcaster_apikey
    FUND_TRANSACTION=your_fund_transaction
    PKEY=your_primary_key
    ``` -->
1. Start the server:
    ```bash
    npm start
    ```
2. The service will be available at `http://localhost:3000`.

## Testing

1. Run the tests:
    ```bash
    npm test
    ```

## Endpoints

### Get Beverages
```http
GET /beverages
```
Returns a list of available beverages as JSON objects.
```json
[
    {
        "name": "Coffee",
        "price": 2.5
    },
    {
        "name": "Tea",
        "price": 1.5
    }
]
```

### Prepare Beverage
```http
POST /beverages
```

The body of the request should contain the following JSON object:
```json
{
    "beverageName": "coffee",
    "sugarLevel": 3,
    "coins": [2, 0.2, 0.2, 0.2 ]
}
```

Prepares the selected beverage and returns the transaction details as a JSON object.
```json
{
    "name": "Coffee",
    "change": [0.5, 1.0],
    "txId": "75cec78bde44180e92a40....d69b39f1624c1c54b538"
}
```

### Get Ingredients
```http
GET /ingredients
```
Returns a list of ingredients and their quantities as JSON objects.
```json
[
    {
        "name": "water",
        "quantity": 1000
    },
    {
        "name": "coffee",
        "quantity": 500
    }
]
```

<!-- ## JSON Propagation to BSV

Successful transactions are propagated as a JSON object into BSV (Bitcoin SV) using the TAAL API to ensure transparency and traceability. -->

## Limitations and Considerations

This solution is a demonstration and has several limitations and considerations to be aware of:

1. **No Authentication**: The solution does not implement any authentication mechanisms.
2. **Limited Automatic Tests**: Only a few automatic tests are included for demonstration purposes.
3. **BSV Change Handling**: Changes of BSV funds are returned to the same address, which is not the best practice. Funds are not prepared in advance.
4. **Primary Key Storage**: The primary key is stored in plain text. If a transaction is not broadcasted successfully, there is no logic to retry.
5. **Hardcoded Data**: All data are hardcoded and stored only in memory. There are no endpoints to refill/manage ingredients.
6. **Limited Logging**: The solution includes limited logging functionality.
7. **No Health Checks**: There are no health check endpoints implemented.
8. **Not Dockerized**: The solution is not containerized using Docker.
9. **NO CI/CD**
10. **No Open API Schema**
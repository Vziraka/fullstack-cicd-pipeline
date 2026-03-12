
// server.js is entry point for the comet order API and listen for incoming request on a specfic port 
// it uses express framwork to create the server and define the route for the API, it also use a router to handle the order related endpoints and logic
// it also include a health check endpoint to verify that the API is running and healthy 


// What is endpoint LOGIC ?
// logic is basically the code that runs when you get a request to a specific endpoint, 
// for example when you get a POST request to /orders you need to create a new order and save it to the database, 
// this is the logic that runs when you get a request to /orders endpoint with POST method.


const express = require('express'); // import express framwork to create the server and handle routing 
//what is the express framwork ? 
//Node.js is the runtime that lets JavaScript run on a server. 
//Express is the framework that runs on top of Node.js and provides pre-built tools for handling HTTP requests 
// like GET, POST, DELETE.

const ordersRouter = require('./routes/orders'); // defines the router for the order related endpoints


const app = express(); // creates the server instance using express



const PORT = process.env.PORT || 3000; // checks PORT based on what enviorment this is running on if it exsist 
                                       // otherwise the port is 3000


                                       app.use(express.json());
// allows serve to take JSON data exmaple "{ "customerId": 123, "items": [ { "productId": 456, "quantity": 2 } ] }"
// without this line server will not be able to parse JSON data from the request body and will give error 


app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'comet-orders-api' });
});
// when the health endpoints is requested, 
// if the API is running it'll return response with status 200 "ok" and "comet-order-api"

app.use('/orders', ordersRouter);
// if /orders is requested the server will use the ordersRouter to take the request to /orders which handles order request


app.listen(PORT, () => {
  console.log(`COMET Orders API running on port ${PORT}`);
});
// tells the server which port to listen for incoming request 
// and puts a message to state that once its running 

module.exports = app; 
// turns the server.js file into a module or reusable piece of code 
// so we can use it in our test file to test the API without having to start the server each time 


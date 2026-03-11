// This is the /order route file that takes all of the order related request and handles the logic for it 

// how the request to response flow works 
//The buyer's dashboard (frontend) fills out a purchase order form and hits submit. 
// for example That triggers a POST /orders request to your API. 
// Your backend doesn't care what the form looks like — 
// it just reads the JSON, creates the order, and sends back confirmation. 
// The frontend then shows "Order created successfully."

const express = require('express'); // imports express framwork 
const { v4: uuidv4 } = require('uuid'); // imports the uuid library to generate Random unique ID for each order
                                        // so there is no collision 

const router = express.Router(); // defines the router for the order endpoints 

const orders = []; // This is a memory array to store the order, 
                   // in a real app you would use a database to store orders

router.post('/', (req, res) => { 
  const { supplierName, amount, status } = req.body;
// when you get a POST request to /orders it will take the supplierName, amount and status from the JSON request body
   



   if (!supplierName || !amount || !status) {
    return res.status(400).json({ error: 'supplierName, amount, and status are required' });
  }
  // this is sayiging that if one of these are not in the reuest to out put a 400 error with a message 
  
  
  const order = {
    id: uuidv4(), 
    supplierName,
    amount,
    status,
    createdAt: new Date().toISOString()
  };
// gives a confirmation that the order is created with a unique ID, the supplierName, amount, status and the time it was created
  


  orders.push(order); 
  res.status(201).json(order);
});
// when the order is created it will put it in the array 
// and return a response with status 201 and the order details in JSON format


router.get('/', (req, res) => {
  res.status(200).json(orders);
});
// check the status of all orders by sending a GET request to /orders, 
// it will return a response with status 200 and list all orders complemeted in JSON format


router.get('/:id', (req, res) => {
  const order = orders.find(o => o.id === req.params.id); 

  // bascially when /order/:id is requested it look for the order with the same ID in the array
  // it does this by doing a loop through it using o as a temporary variable to check each order ID
  // and uses req.params.id to parse the request so the API can understand the :Id
  
  
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  } 
  // if no order return 400 and a message "Order not found" 
  
  
  res.status(200).json(order);
  // if the order is found return 200 and the order details in JSON format 
});

router.put('/:id', (req, res) => {
  const index = orders.findIndex(o => o.id === req.params.id);
  // when /order/:id is requested with PUT method (used to update) it look for the order with the same ID in the array
  // but uses the index to locate it the order in the array 
  if (index === -1) {
    return res.status(404).json({ error: 'Order not found' });
  }
  // if not found return 400 and a message "Order not found"

  const { supplierName, amount, status } = req.body;
  orders[index] = { ...orders[index], supplierName, amount, status };
 // if order found itll update the changed details from the request body and keep the rest the same
  
 
 res.status(200).json(orders[index]);
// reponse will be status 200 and the updated order details in JSON format
});

router.delete('/:id', (req, res) => {
  const index = orders.findIndex(o => o.id === req.params.id);
// whene /order/:id is requested with DELETE method it look for the order with the same ID in the array
//and delete its 
  if (index === -1) {
    return res.status(404).json({ error: 'Order not found' });
  } // if not found return 400 and a message "Order not found"

  orders.splice(index, 1);
  res.status(204).send();
}); // if order found itll delete and the respone will be 204 

module.exports = router;

// turns the orders.js file into a module or reusable piece of code
// also will be used for testing the API 

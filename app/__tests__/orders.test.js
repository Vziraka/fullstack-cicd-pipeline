const request = require('supertest');
const app = require('../server');

describe('GET /health', () => {
  it('returns 200 and status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('POST /orders', () => {
  it('creates a new order and returns 201', async () => {
    const res = await request(app).post('/orders').send({
      supplierName: 'Test Supplier',
      amount: 500,
      status: 'pending'
    });
    expect(res.statusCode).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.supplierName).toBe('Test Supplier');
  });

  it('returns 400 if required fields are missing', async () => {
    const res = await request(app).post('/orders').send({ supplierName: 'Test Supplier' });
    expect(res.statusCode).toBe(400);
  });
});

describe('GET /orders', () => {
  it('returns 200 and an array', async () => {
    const res = await request(app).get('/orders');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});

describe('GET /orders/:id', () => {
  it('returns 404 for a non-existent order', async () => {
    const res = await request(app).get('/orders/non-existent-id');
    expect(res.statusCode).toBe(404);
  });

  it('returns 200 and the order for a valid id', async () => {
    const created = await request(app).post('/orders').send({
      supplierName: 'Acme Corp',
      amount: 1000,
      status: 'approved'
    });
    const res = await request(app).get(`/orders/${created.body.id}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.supplierName).toBe('Acme Corp');
  });
});

describe('PUT /orders/:id', () => {
  it('updates an order and returns 200', async () => {
    const created = await request(app).post('/orders').send({
      supplierName: 'Old Name',
      amount: 100,
      status: 'pending'
    });
    const res = await request(app).put(`/orders/${created.body.id}`).send({
      supplierName: 'New Name',
      amount: 200,
      status: 'approved'
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.supplierName).toBe('New Name');
  });

  it('returns 404 for a non-existent order', async () => {
    const res = await request(app).put('/orders/fake-id').send({
      supplierName: 'X',
      amount: 1,
      status: 'pending'
    });
    expect(res.statusCode).toBe(404);
  });
});

describe('DELETE /orders/:id', () => {
  it('deletes an order and returns 204', async () => {
    const created = await request(app).post('/orders').send({
      supplierName: 'To Delete',
      amount: 50,
      status: 'pending'
    });
    const res = await request(app).delete(`/orders/${created.body.id}`);
    expect(res.statusCode).toBe(204);
  });

  it('returns 404 for a non-existent order', async () => {
    const res = await request(app).delete('/orders/fake-id');
    expect(res.statusCode).toBe(404);
  });
});

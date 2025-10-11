import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { specs } from './swagger';
import tokenRoutes from './routes/tokenRoutes';

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// API Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Solana Token API Documentation'
}));

app.use('/api', tokenRoutes);

// Redirect root to API docs
app.get('/', (req, res) => {
  res.redirect('/api-docs');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
  console.log(`API Documentation available at http://localhost:${port}/api-docs`);
});
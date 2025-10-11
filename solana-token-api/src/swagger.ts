import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Solana Token API',
      version: '1.0.0',
      description: 'A Node.js application for creating and managing custom tokens on the Solana devnet',
      contact: {
        name: 'API Support',
        email: 'support@example.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      }
    ],
    components: {
      schemas: {
        TransferRequest: {
          type: 'object',
          required: ['multiplier'],
          properties: {
            recipientWalletAddress: {
              type: 'string',
              description: 'Recipient wallet address'
            },
            amount: {
              type: 'number',
              description: 'Amount to transfer'
            },
            multiplier: {
              type: 'number',
              description: 'Multiplier for the transfer'
            }
          }
        },
        EquinoxTransferRequest: {
          type: 'object',
          required: ['payerSecretArray', 'recipientWalletAddress', 'amount'],
          properties: {
            payerSecretArray: {
              type: 'array',
              items: {
                type: 'number'
              },
              description: 'Payer secret key as array of numbers'
            },
            recipientWalletAddress: {
              type: 'string',
              description: 'Recipient wallet address'
            },
            amount: {
              type: 'number',
              description: 'Amount of Equinox tokens to transfer'
            }
          }
        },
        BuyEquinoxRequest: {
          type: 'object',
          required: ['recipientWalletAddress', 'amount'],
          properties: {
            recipientWalletAddress: {
              type: 'string',
              description: 'Recipient wallet address'
            },
            amount: {
              type: 'number',
              description: 'Amount of Equinox tokens to buy'
            }
          }
        },
        WalletResponse: {
          type: 'object',
          properties: {
            publicKey: {
              type: 'string',
              description: 'Generated wallet public key'
            },
            secretKey: {
              type: 'array',
              items: {
                type: 'number'
              },
              description: 'Generated wallet secret key'
            }
          }
        },
        BalanceResponse: {
          type: 'object',
          properties: {
            balance: {
              type: 'number',
              description: 'Token balance'
            },
            walletAddress: {
              type: 'string',
              description: 'Wallet address'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              description: 'Error message'
            }
          }
        }
      }
    }
  },
  apis: ['./src/routes/*.ts']
};

export const specs = swaggerJsdoc(options);

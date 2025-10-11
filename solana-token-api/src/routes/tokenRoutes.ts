import { Router } from 'express';
import { transferToken } from '../controllers/tokenController';
import { buyEquinoxToken } from '../buyEquinoxToken'
import { getEquinoxBalance } from '../controllers/tokenController'; // Import the new controller
import { transferEquinox } from '../transferEquinox'; // Import the new controller
import { createEquinoxWallet } from '../controllers/tokenController';


const router = Router();

/**
 * @swagger
 * /api/transfer:
 *   post:
 *     summary: Transfer tokens with multiplier
 *     tags: [Token Operations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/TransferRequest'
 *           example:
 *             recipientWalletAddress: "E8XGmEsPtuqoPdUESRKW7zySo9fusHMveBHqnPLkdk3n"
 *             amount: 1000
 *             multiplier: 2
 *     responses:
 *       200:
 *         description: Transfer successful
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/transferequinox:
 *   post:
 *     summary: Transfer Equinox tokens
 *     tags: [Equinox Operations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/EquinoxTransferRequest'
 *           example:
 *             payerSecretArray: [120, 56, 148, 31, 132]
 *             recipientWalletAddress: "E8XGmEsPtuqoPdUESRKW7zySo9fusHMveBHqnPLkdk3n"
 *             amount: 1000
 *     responses:
 *       200:
 *         description: Transfer successful
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/buyequinox:
 *   post:
 *     summary: Buy Equinox tokens
 *     tags: [Equinox Operations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/BuyEquinoxRequest'
 *           example:
 *             recipientWalletAddress: "E8XGmEsPtuqoPdUESRKW7zySo9fusHMveBHqnPLkdk3n"
 *             amount: 500
 *     responses:
 *       200:
 *         description: Purchase successful
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/equinoxbalance/{walletAddress}:
 *   get:
 *     summary: Check Equinox token balance
 *     tags: [Equinox Operations]
 *     parameters:
 *       - in: path
 *         name: walletAddress
 *         required: true
 *         schema:
 *           type: string
 *         description: Wallet address to check balance for
 *         example: "E8XGmEsPtuqoPdUESRKW7zySo9fusHMveBHqnPLkdk3n"
 *     responses:
 *       200:
 *         description: Balance retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/BalanceResponse'
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/createwallet:
 *   get:
 *     summary: Create a new wallet
 *     tags: [Wallet Operations]
 *     responses:
 *       200:
 *         description: Wallet created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/WalletResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

router.post('/transfer', transferToken);
router.post('/buyequinox', buyEquinoxToken);
router.post('/transferequinox', transferEquinox); // New route for token transfer
router.get('/equinoxbalance/:walletAddress', getEquinoxBalance); // New route for balance retrieval
router.get('/createwallet', createEquinoxWallet); // New route for creating wallets


export default router;
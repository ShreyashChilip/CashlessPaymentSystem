const { Connection, Keypair, PublicKey, Transaction } = require('@solana/web3.js');
const { getOrCreateAssociatedTokenAccount, createTransferInstruction, TOKEN_2022_PROGRAM_ID } = require('@solana/spl-token');
const express = require('express');
const bodyParser = require('body-parser');
const cron = require('node-cron');

const app = express();
app.use(bodyParser.json());

// Solana Devnet connection
const connection = new Connection('https://api.devnet.solana.com', 'confirmed');

const TOKEN_MINT_ADDRESS = '<MINT_ADDRESS>';
const DISTRIBUTOR_PRIVATE_KEY = [];
const distributorKeypair = Keypair.fromSecretKey(Uint8Array.from(DISTRIBUTOR_PRIVATE_KEY));

// API endpoint to transfer tokens
app.post('/transfer-tokens', async (req, res) => {
  const { wallet, multiplyingFactor } = req.body;

  if (!wallet || !multiplyingFactor || multiplyingFactor <= 0) {
    return res.status(400).send('Invalid input: wallet address or multiplying factor is missing/invalid');
  }

  try {
    const mintPublicKey = new PublicKey(TOKEN_MINT_ADDRESS);
    const tokensToDistribute = multiplyingFactor * 10; // Adjust multiplier as needed

    // Get or create the recipient's associated token account
    const recipientWallet = new PublicKey(wallet);
    const recipientTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      distributorKeypair,
      mintPublicKey,
      recipientWallet,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Get the distributor's associated token account
    const distributorTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      distributorKeypair,
      mintPublicKey,
      distributorKeypair.publicKey,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    const transaction = new Transaction().add(
      createTransferInstruction(
        distributorTokenAccount.address,
        recipientTokenAccount.address,
        distributorKeypair.publicKey,
        tokensToDistribute * 1e9, // Convert tokens to smallest unit
        [],
        TOKEN_2022_PROGRAM_ID
      )
    );

    // Send the transaction
    const signature = await connection.sendTransaction(transaction, [distributorKeypair]);

    return res.status(200).json({
      message: 'Tokens transferred successfully',
      transaction: signature
    });
  } catch (error) {
    console.error('Token transfer failed:', error.message);
    return res.status(500).send('Error during token transfer');
  }
});

// Start server on the specified port
const PORT = process.env.PORT || 3030;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});